module Crawler
  # Orchestrates a single, policy-checked fetch of a permitted public page:
  #   validate -> robots.txt -> domain rate limit -> HTTP GET
  # Returns a FetchOutcome describing what happened, for the caller to persist
  # onto a CrawlRun and decide whether to proceed to extraction.
  class PageFetcher
    FetchOutcome = Struct.new(:success?, :http_status, :body, :final_url, :error_code, :error_message, keyword_init: true)

    def initialize(http_client: HttpClient.new, robots_checker: RobotsChecker.new)
      @http_client = http_client
      @robots_checker = robots_checker
    end

    def fetch(raw_url)
      validation = UrlValidator.call(raw_url)
      return blocked(validation.error_code, validation.error_message) unless validation.valid?

      uri = validation.uri

      unless @robots_checker.allowed?(uri)
        return blocked(:robots_disallowed, "This site's robots.txt disallows automated access to that page.")
      end

      policy = CrawlerPolicy.new(uri.host)
      unless policy.allowed?
        return blocked(:rate_limited, "We're checking this store too often right now. Please try again shortly.")
      end
      policy.record_request!

      result = @http_client.get(uri)

      if result.success?
        FetchOutcome.new(success?: true, http_status: result.status, body: result.body, final_url: result.final_url)
      else
        FetchOutcome.new(success?: false, error_code: result.error_code, error_message: result.error_message, http_status: result.status)
      end
    end

    private

    def blocked(code, message)
      FetchOutcome.new(success?: false, error_code: code, error_message: message)
    end
  end
end
