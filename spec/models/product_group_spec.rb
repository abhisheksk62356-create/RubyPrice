require "rails_helper"

RSpec.describe ProductGroup, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:name) }

  describe "#cheapest_tracked_product" do
    it "returns the listing with the lowest price when currencies match" do
      group = create(:product_group)
      pricier = create(:tracked_product, product_group: group, product: create(:product, current_price: 99.99, currency: "USD"))
      cheaper = create(:tracked_product, product_group: group, product: create(:product, current_price: 79.99, currency: "USD"))

      expect(group.cheapest_tracked_product).to eq(cheaper)
      expect(group.mixed_currencies?).to be false
    end

    it "ignores listings that have no price yet" do
      group = create(:product_group)
      unpriced = create(:tracked_product, product_group: group, product: create(:product, current_price: nil))
      priced = create(:tracked_product, product_group: group, product: create(:product, current_price: 50))

      expect(group.cheapest_tracked_product).to eq(priced)
    end

    it "flags mixed currencies instead of picking a misleading winner" do
      group = create(:product_group)
      create(:tracked_product, product_group: group, product: create(:product, current_price: 50, currency: "USD"))
      create(:tracked_product, product_group: group, product: create(:product, current_price: 50, currency: "EUR"))

      expect(group.mixed_currencies?).to be true
    end
  end
end
