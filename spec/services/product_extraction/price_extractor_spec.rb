require "rails_helper"

RSpec.describe ProductExtraction::PriceExtractor do
  subject(:extractor) { described_class.new }

  describe "#parse" do
    it "returns nil for blank input" do
      expect(extractor.parse(nil)).to be_nil
      expect(extractor.parse("")).to be_nil
    end

    it "parses a euro symbol prefix" do
      result = extractor.parse("€49.99")
      expect(result.amount).to eq(BigDecimal("49.99"))
      expect(result.currency).to eq("EUR")
    end

    it "parses a euro symbol suffix with a comma decimal separator" do
      result = extractor.parse("49,99 €")
      expect(result.amount).to eq(BigDecimal("49.99"))
      expect(result.currency).to eq("EUR")
    end

    it "parses an ISO currency code prefix" do
      result = extractor.parse("EUR 49.99")
      expect(result.amount).to eq(BigDecimal("49.99"))
      expect(result.currency).to eq("EUR")
    end

    it "parses a dollar symbol prefix" do
      result = extractor.parse("$59.99")
      expect(result.amount).to eq(BigDecimal("59.99"))
      expect(result.currency).to eq("USD")
    end

    it "parses an ISO currency code suffix" do
      result = extractor.parse("59.99 USD")
      expect(result.amount).to eq(BigDecimal("59.99"))
      expect(result.currency).to eq("USD")
    end

    it "parses European-style thousands separators" do
      result = extractor.parse("1.234,56 €")
      expect(result.amount).to eq(BigDecimal("1234.56"))
    end

    it "parses US-style thousands separators" do
      result = extractor.parse("$1,234.56")
      expect(result.amount).to eq(BigDecimal("1234.56"))
    end

    it "falls back to the provided default currency when none is detected" do
      result = extractor.parse("49.99", default_currency: "GBP")
      expect(result.currency).to eq("GBP")
    end

    it "returns a BigDecimal, never a Float, to avoid floating point money errors" do
      result = extractor.parse("€19.10")
      expect(result.amount).to be_a(BigDecimal)
    end

    it "returns nil when no number can be found" do
      expect(extractor.parse("Contact us for pricing")).to be_nil
    end
  end
end
