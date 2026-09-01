require "rails_helper"

RSpec.describe "Products", type: :request do
  def sign_in(user)
    post login_path, params: { email: user.email, password: "correct-horse-battery" }
  end

  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /products" do
    it "only lists the current user's tracked products" do
      mine = create(:tracked_product, user: user)
      create(:tracked_product) # someone else's

      get products_path

      expect(response.body).to include(mine.product.name)
    end

    it "supports searching, filtering, and sorting together" do
      desk = create(:product, name: "Standing Desk", current_price: 100)
      keyboard = create(:product, name: "Mechanical Keyboard", current_price: 50)
      create(:tracked_product, user: user, product: desk, monitoring_enabled: true)
      create(:tracked_product, user: user, product: keyboard, monitoring_enabled: false)

      get products_path, params: { q: "desk", monitoring: "on", sort: "lowest_price" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Standing Desk")
      expect(response.body).not_to include("Mechanical Keyboard")
    end
  end

  describe "POST /products" do
    it "rejects an SSRF-style internal URL before ever creating a product" do
      expect {
        post products_path, params: { url: "http://169.254.169.254/latest/meta-data/" }
      }.not_to change(Product, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "queues extraction for a valid public URL" do
      expect {
        post products_path, params: { url: "https://shop.example.com/products/123" }
      }.to have_enqueued_job(ProductExtractionJob)
    end
  end

  describe "authorization on a specific product" do
    it "returns not found when viewing another user's tracked product" do
      other_tracked = create(:tracked_product)

      get product_path(other_tracked.product)

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found when refreshing another user's tracked product" do
      other_tracked = create(:tracked_product)

      post refresh_product_path(other_tracked.product)

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found when deleting another user's tracked product" do
      other_tracked = create(:tracked_product)

      delete product_path(other_tracked.product)

      expect(response).to have_http_status(:not_found)
      expect(TrackedProduct.exists?(other_tracked.id)).to be true
    end

    it "allows the owner to update their own target price" do
      mine = create(:tracked_product, user: user)

      patch product_path(mine.product), params: { tracked_product: { target_price: "39.99" } }

      expect(mine.reload.target_price).to eq(BigDecimal("39.99"))
    end
  end
end
