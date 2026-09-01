require "rails_helper"

RSpec.describe ProductExtraction::ExtractorRegistry do
  def fixture(name)
    Rails.root.join("spec/fixtures/#{name}").read
  end

  describe ".extract" do
    it "prefers JSON-LD structured data when present" do
      result = described_class.extract(fixture("product_json_ld.html"), "https://shop.example.com/1")

      expect(result.name).to eq("Wireless Over-Ear Headphones")
      expect(result.price_amount).to eq(BigDecimal("79.99"))
      expect(result.currency).to eq("EUR")
      expect(result.image_url).to eq("https://cdn.example.com/images/headphones.jpg")
      expect(result.availability).to eq("in_stock")
    end

    it "falls back to OpenGraph/meta tags when there is no JSON-LD" do
      result = described_class.extract(fixture("product_page.html"), "https://shop.example.com/2")

      expect(result.name).to eq("Adjustable Standing Desk")
      expect(result.price_amount).to eq(BigDecimal("249.00"))
      expect(result.currency).to eq("USD")
      expect(result.image_url).to eq("https://cdn.example.com/images/desk.jpg")
    end

    it "falls back to CSS selectors when there is no structured data at all" do
      result = described_class.extract(fixture("product_price_formats.html"), "https://shop.example.com/3")

      expect(result.name).to eq("Mechanical Keyboard")
      expect(result.price_amount).to eq(BigDecimal("1234.56"))
      expect(result.currency).to eq("EUR")
    end

    it "defaults availability and currency when nothing is found" do
      result = described_class.extract("<html><body><h1>Mystery</h1></body></html>", "https://shop.example.com/4")

      expect(result.currency).to eq("EUR")
      expect(result.availability).to eq("unknown")
      expect(result.price_amount).to be_nil
    end
  end
end
