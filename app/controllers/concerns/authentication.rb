module Authentication
  extend ActiveSupport::Concern

  SESSION_COOKIE = :session_token

  included do
    before_action :set_current_session
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def set_current_session
    Current.session = find_session_by_cookie
  end

  def find_session_by_cookie
    Session.find_by(id: cookies.signed[SESSION_COOKIE]) if cookies.signed[SESSION_COOKIE]
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url if request.get? || request.head?
    redirect_to login_path
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || dashboard_path
  end

  def authenticated?
    Current.session.present?
  end

  def current_user
    Current.user
  end

  def start_new_session_for(user)
    session_record = user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
    Current.session = session_record
    cookies.signed.permanent[SESSION_COOKIE] = { value: session_record.id, httponly: true, same_site: :lax }
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(SESSION_COOKIE)
  end
end
