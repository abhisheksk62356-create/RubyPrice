module ProductExtraction
  # Fallback extractor used when a page has no usable JSON-LD: OpenGraph
  # metadata, then plain meta tags, then a small set of common CSS selectors
  # stores tend to use for the product title and price.
  class GenericExtractor < BaseExtractor
    PRICE_SELECTORS = [
      "[itemprop='price']",
      "[data-testid='price']",
      ".price",
      ".price_color",
      ".product-price",
      ".product_price",
      "#priceblock_ourprice",
      "#priceblock_dealprice",
      "span.price",
      "p.price",
      "meta[property='product:price:amount']"
    ].freeze

    IMAGE_SELECTORS = [
      "meta[property='og:image']",
      "meta[name='twitter:image']",
      "[itemprop='image']"
    ].freeze

    def extract
      price_text = find_price_text
      parsed = price_extractor.parse(price_text, default_currency: currency_from_meta)

      ExtractedProduct.new(
        name: find_name,
        price_amount: parsed&.amount,
        currency: parsed&.currency,
        image_url: find_image,
        availability: find_availability,
        raw_price_text: price_text
      )
    end

    private

    def find_name
      meta_content("og:title").presence ||
        meta_content("twitter:title").presence ||
        document.at_css("h1")&.text&.strip.presence ||
        document.at_css("title")&.text&.strip
    end

    def find_price_text
      meta_content("og:price:amount").presence ||
        meta_content("product:price:amount").presence ||
        price_from_selectors
    end

    def price_from_selectors
      PRICE_SELECTORS.each do |selector|
        node = document.at_css(selector)
        next unless node

        text = node["content"].presence || node.text.strip
        return text if text.present?
      end

      nil
    end

    def currency_from_meta
      meta_content("og:price:currency").presence || meta_content("product:price:currency").presence
    end

    def find_image
      IMAGE_SELECTORS.each do |selector|
        node = document.at_css(selector)
        content = node && (node["content"] || node["src"])
        return content if content.present?
      end
      nil
    end

    def find_availability
      content = meta_content("og:availability") || meta_content("product:availability")
      case content.to_s
      when /in[\s_-]?stock/i then "in_stock"
      when /out[\s_-]?of[\s_-]?stock/i then "out_of_stock"
      else "unknown"
      end
    end

    def meta_content(property)
      node = document.at_css("meta[property='#{property}']") || document.at_css("meta[name='#{property}']")
      node && node["content"]
    end
  end
end
