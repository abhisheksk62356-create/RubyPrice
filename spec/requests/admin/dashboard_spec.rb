require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  def sign_in(user)
    post login_path, params: { email: user.email, password: "correct-horse-battery" }
  end

  it "blocks a regular member from the admin dashboard" do
    sign_in(create(:user))

    get admin_root_path

    expect(response).to redirect_to(dashboard_path)
  end

  it "allows an admin to view the dashboard" do
    sign_in(create(:user, :admin))

    get admin_root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Admin Dashboard")
  end

  it "redirects an unauthenticated visitor to login" do
    get admin_root_path
    expect(response).to redirect_to(login_path)
  end
end
