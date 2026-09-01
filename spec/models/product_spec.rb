require "rails_helper"

RSpec.describe Product, type: :model do
  subject(:product) { build(:product) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:canonical_url) }
  it { is_expected.to validate_uniqueness_of(:canonical_url) }
  it { is_expected.to have_many(:tracked_products).dependent(:destroy) }
  it { is_expected.to have_many(:price_histories).dependent(:destroy) }
  it { is_expected.to have_many(:crawl_runs).dependent(:destroy) }

  describe "#price_change_amount and #price_change_percent" do
    it "computes a negative change for a price drop" do
      product = build(:product, current_price: 79.99, previous_price: 99.99)

      expect(product.price_change_amount).to eq(BigDecimal("-20.00"))
      expect(product.price_change_percent).to eq(-20.0)
      expect(product.price_drop?).to be true
    end

    it "returns nil when there is no previous price yet" do
      product = build(:product, current_price: 79.99, previous_price: nil)

      expect(product.price_change_amount).to be_nil
      expect(product.price_drop?).to be false
    end
  end

  describe "#record_price!" do
    it "creates a price history row and shifts current/previous price" do
      product = create(:product, current_price: 100, previous_price: nil)

      expect { product.record_price!(90) }.to change { product.price_histories.count }.by(1)

      product.reload
      expect(product.current_price).to eq(BigDecimal("90"))
      expect(product.previous_price).to eq(BigDecimal("100"))
    end
  end

  describe "scopes" do
    it ".monitored only returns products with monitoring enabled" do
      on = create(:product, monitoring_enabled: true)
      create(:product, monitoring_enabled: false)

      expect(Product.monitored).to contain_exactly(on)
    end

    it ".search_by_name matches name or domain" do
      match = create(:product, name: "Mechanical Keyboard", domain: "keys.example.com")
      create(:product, name: "Standing Desk", domain: "desks.example.com")

      expect(Product.search_by_name("keyboard")).to contain_exactly(match)
      expect(Product.search_by_name("keys.example")).to contain_exactly(match)
    end
  end
end
