module Crawler
  # Fetches and parses a site's robots.txt so the crawler only visits paths
  # the site has permitted for our user agent. Results are cached in Redis
  # (via Rails.cache) for a while so we don't refetch robots.txt on every
  # single product check.
  class RobotsChecker
    CACHE_TTL = 1.hour
    FETCH_TIMEOUT = 5

    Rule = Struct.new(:type, :path)

    def initialize(user_agent: Rails.application.config.x.crawler_user_agent)
      @user_agent = user_agent
    end

    # Returns true when the given absolute URL is allowed to be fetched.
    # Fails open (allowed) if robots.txt cannot be retrieved at all, which
    # matches standard crawler behavior for a missing robots.txt.
    def allowed?(uri)
      rules = rules_for(uri)
      return true if rules.nil? || rules.empty?

      path = uri.path.presence || "/"
      path = "#{path}?#{uri.query}" if uri.query.present?

      matches = rules.select { |rule| path.start_with?(rule.path) }
      return true if matches.empty?

      best_match = matches.max_by { |rule| rule.path.length }
      best_match.type != :disallow
    end

    private

    def rules_for(uri)
      cache_key = "robots_txt:#{uri.host.downcase}"

      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        fetch_and_parse(uri)
      end
    end

    def fetch_and_parse(uri)
      robots_uri = uri.dup
      robots_uri.path = "/robots.txt"
      robots_uri.query = nil
      robots_uri.fragment = nil

      body = fetch_body(robots_uri)
      return [] if body.nil?

      parse(body)
    end

    def fetch_body(robots_uri)
      response = Faraday.new do |f|
        f.options.open_timeout = FETCH_TIMEOUT
        f.options.timeout = FETCH_TIMEOUT
        f.headers["User-Agent"] = @user_agent
        f.adapter Faraday.default_adapter
      end.get(robots_uri.to_s)

      return nil unless response.status == 200

      response.body.to_s.byteslice(0, 100_000)
    rescue Faraday::Error, URI::InvalidURIError
      nil
    end

    def parse(body)
      groups = build_groups(body)
      our_token = @user_agent.split("/").first.to_s.downcase

      exact_match = groups.find { |group| group[:agents].any? { |agent| agent == our_token } }
      wildcard_match = groups.find { |group| group[:agents].include?("*") }

      (exact_match || wildcard_match || { rules: [] })[:rules]
    end

    # Groups robots.txt into { agents: [...], rules: [...] } records, per the
    # standard: consecutive User-agent lines share the directives that follow
    # them, until the next User-agent block begins.
    def build_groups(body)
      groups = []
      pending_agents = []
      current_rules = nil

      body.each_line do |raw_line|
        line = raw_line.split("#").first.to_s.strip
        next if line.empty?

        key, value = line.split(":", 2)
        next unless key && value

        key = key.strip.downcase
        value = value.strip

        case key
        when "user-agent"
          if current_rules
            pending_agents = []
            current_rules = nil
          end
          pending_agents << value.downcase
        when "disallow"
          current_rules ||= start_group(groups, pending_agents)
          current_rules << Rule.new(:disallow, value) unless value.empty?
        when "allow"
          current_rules ||= start_group(groups, pending_agents)
          current_rules << Rule.new(:allow, value)
        end
      end

      groups
    end

    def start_group(groups, agents)
      rules = []
      groups << { agents: agents.dup, rules: rules }
      rules
    end
  end
end
