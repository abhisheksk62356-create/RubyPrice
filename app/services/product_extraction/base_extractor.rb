module ProductExtraction
  # Common value object every extractor strategy returns, plus the interface
  # each strategy implements. Extractors never raise for "couldn't find it" —
  # they simply leave that field nil so a later strategy (or the registry's
  # merge step) can fill it in.
  ExtractedProduct = Struct.new(
    :name, :price_amount, :currency, :image_url, :availability, :raw_price_text,
    keyword_init: true
  ) do
    def any_data?
      [ name, price_amount, image_url ].any?(&:present?)
    end
  end

  class BaseExtractor
    def initialize(document, url)
      @document = document
      @url = url
    end

    # @return [ExtractedProduct]
    def extract
      raise NotImplementedError, "#{self.class} must implement #extract"
    end

    private

    attr_reader :document, :url

    def price_extractor
      @price_extractor ||= PriceExtractor.new
    end
  end
end
