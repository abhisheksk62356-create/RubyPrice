require "resolv"
require "ipaddr"

module Crawler
  # Validates and normalizes a user-submitted product URL before it is ever
  # handed to an HTTP client, defending against SSRF: requests aimed at
  # localhost, private networks, cloud metadata endpoints, or unsafe schemes.
  class UrlValidator
    Result = Struct.new(:valid?, :uri, :error_code, :error_message, keyword_init: true)

    ALLOWED_SCHEMES = %w[http https].freeze

    BLOCKED_HOSTNAME_SUFFIXES = %w[.local .internal .localhost .lan .home .corp].freeze

    BLOCKED_HOSTNAMES = %w[localhost metadata.google.internal].freeze

    # Cloud metadata service addresses (AWS, GCP, Azure, Alibaba, DigitalOcean).
    BLOCKED_IPS = %w[169.254.169.254 fd00:ec2::254].freeze

    BLOCKED_IPV4_RANGES = [
      IPAddr.new("0.0.0.0/8"),
      IPAddr.new("10.0.0.0/8"),
      IPAddr.new("100.64.0.0/10"),
      IPAddr.new("127.0.0.0/8"),
      IPAddr.new("169.254.0.0/16"),
      IPAddr.new("172.16.0.0/12"),
      IPAddr.new("192.0.0.0/24"),
      IPAddr.new("192.0.2.0/24"),
      IPAddr.new("192.168.0.0/16"),
      IPAddr.new("198.18.0.0/15"),
      IPAddr.new("198.51.100.0/24"),
      IPAddr.new("203.0.113.0/24"),
      IPAddr.new("224.0.0.0/4"),
      IPAddr.new("240.0.0.0/4")
    ].freeze

    BLOCKED_IPV6_RANGES = [
      IPAddr.new("::1/128"),
      IPAddr.new("::/128"),
      IPAddr.new("::ffff:0:0/96"),
      IPAddr.new("64:ff9b::/96"),
      IPAddr.new("100::/64"),
      IPAddr.new("fc00::/7"),
      IPAddr.new("fe80::/10")
    ].freeze

    MAX_URL_LENGTH = 2048

    def self.call(raw_url) = new(raw_url).call

    def initialize(raw_url)
      @raw_url = raw_url.to_s.strip
    end

    def call
      return failure(:blank_url, "Please provide a product URL.") if @raw_url.blank?
      return failure(:url_too_long, "That URL is too long.") if @raw_url.length > MAX_URL_LENGTH

      uri = parse_uri
      return failure(:invalid_url, "Please provide a valid product URL.") unless uri

      scheme_check = check_scheme(uri)
      return scheme_check if scheme_check

      return failure(:invalid_url, "The URL is missing a host.") if uri.host.blank?

      host = uri.host.downcase

      hostname_check = check_hostname(host)
      return hostname_check if hostname_check

      ip_check = check_ip_literal_or_dns(host)
      return ip_check if ip_check

      Result.new(valid?: true, uri: normalize(uri))
    end

    private

    def parse_uri
      URI.parse(@raw_url)
    rescue URI::InvalidURIError
      nil
    end

    def check_scheme(uri)
      return nil if ALLOWED_SCHEMES.include?(uri.scheme.to_s.downcase)

      failure(:unsupported_scheme, "Only http and https URLs are supported.")
    end

    def check_hostname(host)
      return failure(:blocked_host, "This host cannot be crawled.") if BLOCKED_HOSTNAMES.include?(host)

      if BLOCKED_HOSTNAME_SUFFIXES.any? { |suffix| host.end_with?(suffix) }
        return failure(:blocked_host, "This host cannot be crawled.")
      end

      nil
    end

    def check_ip_literal_or_dns(host)
      literal_ip = begin
        IPAddr.new(host)
      rescue IPAddr::Error
        nil
      end

      if literal_ip
        return failure(:blocked_ip, "This address cannot be crawled.") if blocked_ip?(literal_ip)

        return nil
      end

      resolve_and_check(host)
    end

    def resolve_and_check(host)
      addresses = Resolv.getaddresses(host)
      return failure(:dns_resolution_failed, "We couldn't resolve that domain.") if addresses.empty?

      addresses.each do |address|
        ip = begin
          IPAddr.new(address)
        rescue IPAddr::Error
          next
        end

        return failure(:blocked_ip, "This address cannot be crawled.") if blocked_ip?(ip)
      end

      nil
    rescue Resolv::ResolvError, Resolv::ResolvTimeout
      failure(:dns_resolution_failed, "We couldn't resolve that domain.")
    end

    def blocked_ip?(ip)
      return true if BLOCKED_IPS.include?(ip.to_s)

      ranges = ip.ipv4? ? BLOCKED_IPV4_RANGES : BLOCKED_IPV6_RANGES
      ranges.any? { |range| range.include?(ip) }
    end

    def normalize(uri)
      uri.host = uri.host.downcase
      uri.fragment = nil
      uri.normalize
    end

    def failure(code, message)
      Result.new(valid?: false, error_code: code, error_message: message)
    end
  end
end
