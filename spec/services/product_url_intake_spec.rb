require "rails_helper"

RSpec.describe ProductUrlIntake do
  let(:user) { create(:user) }

  describe ".call" do
    it "creates a Product, TrackedProduct, and CrawlRun, and enqueues extraction" do
      result = nil

      expect {
        result = described_class.call(user: user, raw_url: "https://shop.example.com/products/42")
      }.to have_enqueued_job(ProductExtractionJob)

      expect(result.success?).to be true
      expect(result.product).to be_persisted
      expect(result.tracked_product.user).to eq(user)
      expect(result.crawl_run.status).to eq("pending")
    end

    it "reuses an existing Product when the canonical URL is already tracked by someone else" do
      existing = create(:product, canonical_url: "https://shop.example.com/products/42")

      result = described_class.call(user: user, raw_url: "https://shop.example.com/products/42")

      expect(result.product).to eq(existing)
      expect(Product.count).to eq(1)
    end

    it "does not allow a second TrackedProduct row for the same user/product pair" do
      described_class.call(user: user, raw_url: "https://shop.example.com/products/42")

      expect {
        described_class.call(user: user, raw_url: "https://shop.example.com/products/42")
      }.not_to change(TrackedProduct, :count)
    end

    it "rejects an SSRF-unsafe URL and creates nothing" do
      expect {
        result = described_class.call(user: user, raw_url: "http://localhost/admin")
        expect(result.success?).to be false
      }.not_to change(Product, :count)
    end
  end
end
