require "nokogiri"

module ProductExtraction
  # Runs extraction strategies in priority order (JSON-LD structured data
  # first, then OpenGraph/meta/CSS fallbacks) and merges their results so
  # that a field found by a lower-priority strategy fills gaps left by a
  # higher-priority one.
  class ExtractorRegistry
    STRATEGIES = [ JsonLdExtractor, GenericExtractor ].freeze

    def self.extract(html, url) = new.extract(html, url)

    def extract(html, url)
      document = Nokogiri::HTML(html)

      results = STRATEGIES.map { |strategy_class| strategy_class.new(document, url).extract }

      merge(results)
    end

    private

    def merge(results)
      ExtractedProduct.new(
        name: first_present(results, :name),
        price_amount: first_present(results, :price_amount),
        currency: first_present(results, :currency) || "EUR",
        image_url: first_present(results, :image_url),
        availability: first_present(results, :availability) || "unknown",
        raw_price_text: first_present(results, :raw_price_text)
      )
    end

    def first_present(results, field)
      results.map { |result| result[field] }.find(&:present?)
    end
  end
end
