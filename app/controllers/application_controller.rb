class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  #before_action :validate_token

  def decode_jwt(token)
    data = JWT.decode token, Rails.application.secrets.token[:secret], true, { algorithm: Rails.application.secrets.token[:algorithm] }
    data[0]
  end

  def generate_crypt
    key = Rails.application.secrets.user_password_encrypt_key
    logger.info("************ #{key}")
    ActiveSupport::MessageEncryptor.new(key)
  end

  def validate_token
    logger.info("********* validate token has been called")
    if params[:token].present?
      token = UserValidationToken.find_by_token(params[:token])
      handle_token_validation(token)
    end
  end

  private

  def handle_token_validation(token)
    if token.expires_at > DateTime.current
      refresh_token(token)
    else
      render json: {status: 'ERROR', message: 'Token expired'}, status: :unprocessable_entity
    end
  end

  def refresh_token(token)
    token.update(expires_at: DateTime.current)
  end
end
