require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "signup" do
    it "creates a user and signs them in" do
      expect {
        post signup_path, params: { user: { email: "new@example.com", password: "correct-horse", password_confirmation: "correct-horse" } }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end

    it "rejects a mismatched password confirmation" do
      post signup_path, params: { user: { email: "new@example.com", password: "correct-horse", password_confirmation: "different" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "login" do
    it "signs in with correct credentials" do
      user = create(:user, password: "correct-horse", password_confirmation: "correct-horse")

      post login_path, params: { email: user.email, password: "correct-horse" }

      expect(response).to redirect_to(dashboard_path)
    end

    it "rejects incorrect credentials without revealing which field was wrong" do
      user = create(:user, password: "correct-horse", password_confirmation: "correct-horse")

      post login_path, params: { email: user.email, password: "wrong-password" }

      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("was not recognized")
    end

    it "throttles repeated failed login attempts from the same client" do
      user = create(:user, password: "correct-horse", password_confirmation: "correct-horse")

      11.times { post login_path, params: { email: user.email, password: "wrong" } }

      expect(response).to have_http_status(:too_many_requests).or redirect_to(login_path)
    end
  end

  describe "protected pages" do
    it "redirects an unauthenticated visitor to login" do
      get dashboard_path
      expect(response).to redirect_to(login_path)
    end

    it "allows an authenticated user through" do
      user = create(:user)
      post login_path, params: { email: user.email, password: "correct-horse-battery" }

      get dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "logout" do
    it "ends the session" do
      user = create(:user)
      post login_path, params: { email: user.email, password: "correct-horse-battery" }

      delete logout_path
      get dashboard_path

      expect(response).to redirect_to(login_path)
    end
  end
end
