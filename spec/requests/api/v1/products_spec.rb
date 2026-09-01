require "rails_helper"

RSpec.describe "Api::V1::Products", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{user.api_token}" } }

  describe "authentication" do
    it "rejects requests without a token" do
      get api_v1_products_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with an invalid token" do
      get api_v1_products_path, headers: { "Authorization" => "Bearer not-a-real-token" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/products" do
    it "returns only the authenticated user's tracked products" do
      mine = create(:tracked_product, user: user)
      create(:tracked_product, user: other_user)

      get api_v1_products_path, headers: headers

      body = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(body["products"].map { |p| p["id"] }).to eq([ mine.product_id ])
    end
  end

  describe "GET /api/v1/products/:id" do
    it "returns 404 for a product tracked by a different user" do
      other_tracked = create(:tracked_product, user: other_user)

      get api_v1_product_path(other_tracked.product), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/products" do
    it "creates a tracked product for a valid URL" do
      post api_v1_products_path, params: { url: "https://shop.example.com/products/1" }, headers: headers

      expect(response).to have_http_status(:created)
    end

    it "returns a structured error for an SSRF-blocked URL" do
      post api_v1_products_path, params: { url: "http://127.0.0.1/" }, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["error"]["code"]).to be_present
    end
  end

  describe "DELETE /api/v1/products/:id" do
    it "does not allow deleting another user's tracked product" do
      other_tracked = create(:tracked_product, user: other_user)

      delete api_v1_product_path(other_tracked.product), headers: headers

      expect(response).to have_http_status(:not_found)
      expect(TrackedProduct.exists?(other_tracked.id)).to be true
    end
  end
end
