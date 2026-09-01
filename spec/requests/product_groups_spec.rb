require "rails_helper"

RSpec.describe "ProductGroups", type: :request do
  def sign_in(user)
    post login_path, params: { email: user.email, password: "correct-horse-battery" }
  end

  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "POST /compare" do
    it "creates a comparison and links a preselected tracked product" do
      tracked = create(:tracked_product, user: user)

      expect {
        post product_groups_path, params: { product_group: { name: "iPhone 15 Pro" }, tracked_product_id: tracked.id }
      }.to change(ProductGroup, :count).by(1)

      expect(tracked.reload.product_group).to eq(ProductGroup.last)
      expect(response).to redirect_to(product_group_path(ProductGroup.last))
    end
  end

  describe "authorization" do
    it "does not let a user view another user's comparison" do
      other_group = create(:product_group)

      get product_group_path(other_group)

      expect(response).to have_http_status(:not_found)
    end

    it "does not let a user delete another user's comparison" do
      other_group = create(:product_group)

      delete product_group_path(other_group)

      expect(response).to have_http_status(:not_found)
      expect(ProductGroup.exists?(other_group.id)).to be true
    end

    it "does not let a user add someone else's tracked product into their own comparison" do
      my_group = create(:product_group, user: user)
      someone_elses_tracked_product = create(:tracked_product)

      post product_group_memberships_path(my_group), params: { tracked_product_id: someone_elses_tracked_product.id }

      expect(response).to have_http_status(:not_found)
      expect(someone_elses_tracked_product.reload.product_group_id).to be_nil
    end
  end

  describe "DELETE /compare/:id/memberships/:id" do
    it "unlinks a tracked product without deleting it" do
      group = create(:product_group, user: user)
      tracked = create(:tracked_product, user: user, product_group: group)

      delete product_group_membership_path(group, tracked)

      expect(tracked.reload.product_group_id).to be_nil
      expect(TrackedProduct.exists?(tracked.id)).to be true
    end
  end
end
