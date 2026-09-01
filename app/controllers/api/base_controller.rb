module Api
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    # Per-IP/per-token throttling for the whole /api namespace is handled by
    # Rack::Attack (see config/initializers/rack_attack.rb) so it applies
    # before Rails routing even runs.

    before_action :authenticate_with_token!

    rescue_from ActiveRecord::RecordNotFound, with: -> { render_error(:not_found, "NOT_FOUND", "Record not found.") }
    rescue_from ActiveRecord::RecordInvalid, with: :render_invalid_record

    private

    def authenticate_with_token!
      authenticate_or_request_with_http_token do |token, _options|
        @current_user = User.find_by(api_token: token)
      end
    end

    def current_user
      @current_user
    end

    def render_invalid_record(exception)
      render_error(:unprocessable_content, "VALIDATION_FAILED", exception.record.errors.full_messages.to_sentence)
    end

    def render_error(status, code, message)
      render json: { error: { code: code, message: message } }, status: status
    end
  end
end
