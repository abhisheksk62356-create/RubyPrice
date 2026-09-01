require "faraday"

module Crawler
  # A hardened Faraday client for fetching third-party product pages: strict
  # timeouts, a capped response size, a small number of redirects (each of
  # which is re-validated against the SSRF blocklist), and a clear User-Agent
  # so site owners can identify and block us if they wish.
  class HttpClient
    MAX_REDIRECTS = 3

    FetchResult = Struct.new(:success?, :status, :body, :final_url, :error_code, :error_message, keyword_init: true)

    def initialize(
      user_agent: Rails.application.config.x.crawler_user_agent,
      open_timeout: Rails.application.config.x.crawler_timeout_seconds,
      timeout: Rails.application.config.x.crawler_timeout_seconds,
      max_bytes: Rails.application.config.x.crawler_max_response_bytes
    )
      @user_agent = user_agent
      @open_timeout = open_timeout
      @timeout = timeout
      @max_bytes = max_bytes
    end

    def get(uri)
      current_uri = uri
      redirects_followed = 0

      loop do
        validation = UrlValidator.call(current_uri.to_s)
        unless validation.valid?
          return FetchResult.new(success?: false, error_code: validation.error_code, error_message: validation.error_message)
        end

        response = perform_request(validation.uri)

        if redirect?(response) && redirects_followed < MAX_REDIRECTS
          location = response.headers["location"]
          return blocked_redirect_result unless location

          current_uri = resolve_redirect(current_uri, location)
          redirects_followed += 1
          next
        end

        return build_result(response, current_uri)
      end
    rescue Faraday::TimeoutError
      FetchResult.new(success?: false, error_code: :timeout, error_message: "The page took too long to respond.")
    rescue Faraday::ConnectionFailed => e
      if timeout_error?(e)
        FetchResult.new(success?: false, error_code: :timeout, error_message: "The page took too long to respond.")
      else
        FetchResult.new(success?: false, error_code: :connection_failed, error_message: "Could not connect to that host.")
      end
    rescue Faraday::Error => e
      FetchResult.new(success?: false, error_code: :http_error, error_message: e.message)
    end

    private

    def timeout_error?(exception)
      exception.is_a?(Timeout::Error) ||
        exception.message.to_s.match?(/timeout/i) ||
        exception.cause.is_a?(Timeout::Error)
    end

    def perform_request(uri)
      connection.get(uri.to_s)
    end

    def connection
      @connection ||= Faraday.new do |f|
        f.options.open_timeout = @open_timeout
        f.options.timeout = @timeout
        f.headers["User-Agent"] = @user_agent
        f.headers["Accept"] = "text/html,application/xhtml+xml"
        f.adapter Faraday.default_adapter
      end
    end

    def redirect?(response)
      [ 301, 302, 303, 307, 308 ].include?(response.status)
    end

    def resolve_redirect(current_uri, location)
      URI.join(current_uri, location)
    rescue URI::InvalidURIError, ArgumentError
      current_uri
    end

    def blocked_redirect_result
      FetchResult.new(success?: false, error_code: :invalid_redirect, error_message: "The page redirected somewhere we can't follow.")
    end

    def build_result(response, final_uri)
      unless response.status == 200
        return FetchResult.new(success?: false, status: response.status, error_code: :bad_status, error_message: "The page responded with status #{response.status}.")
      end

      body = response.body.to_s
      body = body.byteslice(0, @max_bytes) if body.bytesize > @max_bytes

      FetchResult.new(success?: true, status: response.status, body: body, final_url: final_uri.to_s)
    end
  end
end
