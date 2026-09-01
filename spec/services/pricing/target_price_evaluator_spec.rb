require "rails_helper"

RSpec.describe Pricing::TargetPriceEvaluator do
  describe ".call" do
    it "triggers an alert for a user whose target price has been reached" do
      product = create(:product, current_price: 45.00)
      user = create(:user)
      create(:tracked_product, user: user, product: product, target_price: 49.99)

      alerts = described_class.call(product)

      expect(alerts.size).to eq(1)
      expect(alerts.first.status).to eq("triggered")
      expect(alerts.first.triggered_price).to eq(BigDecimal("45.00"))
    end

    it "does not trigger an alert when the price is still above target" do
      product = create(:product, current_price: 59.99)
      user = create(:user)
      create(:tracked_product, user: user, product: product, target_price: 49.99)

      expect(described_class.call(product)).to be_empty
      expect(PriceAlert.count).to eq(0)
    end

    it "does not re-trigger an alert that has already fired" do
      product = create(:product, current_price: 45.00)
      user = create(:user)
      create(:tracked_product, user: user, product: product, target_price: 49.99)

      described_class.call(product)
      second_run = described_class.call(product)

      expect(PriceAlert.count).to eq(1)
      expect(second_run).to eq([])
    end

    it "ignores tracked products with no target price set" do
      product = create(:product, current_price: 10.00)
      create(:tracked_product, product: product, target_price: nil)

      expect(described_class.call(product)).to be_empty
    end
  end
end
