module Crawler
  # Per-domain rate limiting for the crawler itself, so RubyPrice never hammers
  # a single store with requests. Backed by Redis via Rails.cache counters.
  class CrawlerPolicy
    MAX_REQUESTS_PER_DOMAIN_PER_MINUTE = 6

    def initialize(domain)
      @domain = domain.to_s.downcase
    end

    def allowed?
      current_count < MAX_REQUESTS_PER_DOMAIN_PER_MINUTE
    end

    def record_request!
      Rails.cache.increment(cache_key, 1, expires_in: 1.minute) || Rails.cache.write(cache_key, 1, expires_in: 1.minute)
    end

    private

    def current_count
      Rails.cache.read(cache_key).to_i
    end

    def cache_key
      "crawler_policy:#{@domain}:#{Time.current.strftime('%Y%m%d%H%M')}"
    end
  end
end
