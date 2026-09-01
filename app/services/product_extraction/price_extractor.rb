require "bigdecimal"

module ProductExtraction
  # Parses free-form price text ("€49.99", "49,99 €", "EUR 49.99", "$59.99",
  # "1.234,56 USD") into a decimal-safe amount and an ISO 4217 currency code.
  # Never uses floating point for money.
  class PriceExtractor
    Result = Struct.new(:amount, :currency, keyword_init: true)

    SYMBOL_TO_CURRENCY = {
      "€" => "EUR",
      "$" => "USD",
      "£" => "GBP",
      "¥" => "JPY",
      "₹" => "INR",
      "₩" => "KRW",
      "₪" => "ILS",
      "₺" => "TRY",
      "zł" => "PLN",
      "kr" => "SEK"
    }.freeze

    KNOWN_CURRENCY_CODES = %w[
      EUR USD GBP JPY CHF CAD AUD NZD SEK NOK DKK PLN CZK HUF RON
      INR KRW ILS TRY BRL MXN ZAR SGD HKD CNY AED SAR
    ].freeze

    NUMBER_PATTERN = /(\d[\d.,\s ]*\d|\d)/

    def self.parse(raw, default_currency: nil) = new.parse(raw, default_currency: default_currency)

    def parse(raw, default_currency: nil)
      return nil if raw.blank?

      text = raw.to_s.strip
      currency = detect_currency(text) || default_currency
      amount = extract_amount(text)

      return nil if amount.nil?

      Result.new(amount: amount, currency: currency)
    end

    private

    def detect_currency(text)
      code_match = text.match(/\b([A-Z]{3})\b/)
      return code_match[1] if code_match && KNOWN_CURRENCY_CODES.include?(code_match[1])

      SYMBOL_TO_CURRENCY.each do |symbol, code|
        return code if text.include?(symbol)
      end

      nil
    end

    def extract_amount(text)
      match = text.match(NUMBER_PATTERN)
      return nil unless match

      normalize_number(match[1])
    end

    # Handles both "1,234.56" (US) and "1.234,56" (EU) grouping styles, plus
    # bare "49,99" / "49.99" without thousands separators.
    def normalize_number(raw_number)
      cleaned = raw_number.gsub(/[\s ]/, "")
      has_comma = cleaned.include?(",")
      has_dot = cleaned.include?(".")

      normalized =
        if has_comma && has_dot
          if cleaned.rindex(",") > cleaned.rindex(".")
            cleaned.delete(".").sub(",", ".")
          else
            cleaned.delete(",")
          end
        elsif has_comma
          decimal_group?(cleaned, ",") ? cleaned.sub(",", ".") : cleaned.delete(",")
        elsif has_dot
          decimal_group?(cleaned, ".") ? cleaned : cleaned.delete(".")
        else
          cleaned
        end

      BigDecimal(normalized)
    rescue ArgumentError
      nil
    end

    # A trailing group of exactly 1-2 digits after the separator (e.g. "49,9"
    # or "49,99") reads as a decimal fraction; three digits ("1,234") reads as
    # a thousands separator instead.
    def decimal_group?(number, separator)
      fraction = number.split(separator).last
      fraction.length <= 2
    end
  end
end
