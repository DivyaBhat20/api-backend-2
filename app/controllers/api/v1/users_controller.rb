class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  def sign_up
    begin
      form_data = decode_jwt(params[:token])
      create_user(form_data)
      render json: {state: 'SUCCESS'}
    rescue => exception
      render json: { state: 'FAILED', error: exception }
    end
  end

  def sign_in
    begin
      form_data = decode_jwt(params[:token])
      user = fetch_user(form_data)
      authenticate_user(form_data, user)
    rescue => exception
      render json: { state: 'FAILED', error: exception }
    end
  end

  private

  def create_user(form_data)
    email = form_data["email"]
    password = form_data["password"]
    crypt = generate_crypt
    encrypted_pwd = crypt.encrypt_and_sign(password)
    User.create!(email: email, password: encrypted_pwd)
  end

  def fetch_user(form_data)
    email = form_data["email"]
    user = User.find_by_email(email)
  end

  def authenticate_user(form_data, user)
    password = form_data["password"]
    crypt = generate_crypt
    decrypt = crypt.decrypt_and_verify(user.password)
    if password == decrypt
      token = generate_session_token(user)
      render json: {state: 'SUCCESS', token: token.token, id: user.id}
    else
      render json: {state: 'FAILED', error: 'Password Mismatch'}
    end
  end

  def generate_session_token(user)
    UserValidationToken.create!(token: SecureRandom.alphanumeric(10), user: user)
  end
end
