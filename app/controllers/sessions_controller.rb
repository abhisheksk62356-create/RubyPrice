class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "Too many login attempts. Please wait a few minutes and try again." }

  def new
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user&.authenticate(params[:password])
      start_new_session_for(user)
      redirect_to after_authentication_url, notice: "Welcome back."
    else
      redirect_to login_path, alert: "That email or password was not recognized."
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "You have been signed out."
  end
end
