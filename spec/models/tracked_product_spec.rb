require "rails_helper"

RSpec.describe TrackedProduct, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:product) }

  it "prevents the same user from tracking the same product twice" do
    product = create(:product)
    user = create(:user)
    create(:tracked_product, user: user, product: product)

    duplicate = build(:tracked_product, user: user, product: product)

    expect(duplicate).not_to be_valid
  end

  describe "#target_reached?" do
    it "is true once the current price falls to or below the target" do
      product = create(:product, current_price: 49.99)
      tracked = create(:tracked_product, product: product, target_price: 49.99)

      expect(tracked.target_reached?).to be true
    end

    it "is false while the current price is still above the target" do
      product = create(:product, current_price: 59.99)
      tracked = create(:tracked_product, product: product, target_price: 49.99)

      expect(tracked.target_reached?).to be false
    end

    it "is false when no target price is set" do
      tracked = create(:tracked_product, target_price: nil)
      expect(tracked.target_reached?).to be false
    end
  end
end
