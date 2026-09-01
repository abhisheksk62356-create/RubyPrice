class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    redirect_to dashboard_path and return if authenticated?
  end

  def features
  end
end
