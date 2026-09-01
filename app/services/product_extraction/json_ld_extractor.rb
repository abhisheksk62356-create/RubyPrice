require "json"

module ProductExtraction
  # Extracts product data from schema.org JSON-LD <script type="application/ld+json">
  # blocks. This is the most reliable source when present, since it's
  # structured data the store published for search engines.
  class JsonLdExtractor < BaseExtractor
    def extract
      product_node = find_product_node
      return ExtractedProduct.new unless product_node

      offer = extract_offer(product_node)

      ExtractedProduct.new(
        name: product_node["name"].presence,
        price_amount: parse_price(offer&.[]("price")),
        currency: offer&.[]("priceCurrency").presence,
        image_url: extract_image(product_node),
        availability: normalize_availability(offer&.[]("availability")),
        raw_price_text: offer&.[]("price")&.to_s
      )
    end

    private

    def find_product_node
      each_json_ld_node do |node|
        return node if product_type?(node)
      end
      nil
    end

    def each_json_ld_node
      document.css('script[type="application/ld+json"]').each do |script|
        data = JSON.parse(script.text)
        flatten_nodes(data).each { |node| yield node }
      rescue JSON::ParserError
        next
      end
    end

    def flatten_nodes(data)
      case data
      when Array
        data.flat_map { |item| flatten_nodes(item) }
      when Hash
        graph = data["@graph"]
        graph ? flatten_nodes(graph) : [ data ]
      else
        []
      end
    end

    def product_type?(node)
      type = node["@type"]
      Array(type).any? { |t| t.to_s.casecmp("product").zero? }
    end

    def extract_offer(product_node)
      offers = product_node["offers"]
      offers = offers.first if offers.is_a?(Array)
      offers.is_a?(Hash) ? offers : nil
    end

    def extract_image(product_node)
      image = product_node["image"]
      image = image.first if image.is_a?(Array)
      image.is_a?(Hash) ? image["url"] : image
    end

    def parse_price(raw_price)
      return nil if raw_price.blank?

      price_extractor.parse(raw_price.to_s)&.amount
    end

    def normalize_availability(schema_availability)
      return "unknown" if schema_availability.blank?

      case schema_availability.to_s
      when /InStock/i then "in_stock"
      when /OutOfStock|SoldOut/i then "out_of_stock"
      else "unknown"
      end
    end
  end
end
