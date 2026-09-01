class SettingsController < ApplicationController
  def show
  end

  def update
    if current_user.update(settings_params)
      redirect_to settings_path, notice: "Your settings have been updated."
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def settings_params
    params.require(:user).permit(:email, :password, :password_confirmation).select { |_, v| v.present? }
  end
end
