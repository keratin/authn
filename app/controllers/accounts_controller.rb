class AccountsController < ApplicationController
  before_action :require_trusted_referrer, only: [:create]

  # params:
  # * username
  # * password
  def create
    account = Account.new(
      username: params[:username]
    )
    account.password = BCrypt::Password.create(params[:password]).to_s if params[:password].present?

    if params[:password].present?
      # SECURITY NOTE:
      #
      # this password complexity algorithm is expensive and scales exponentially to the length
      # of the provided string. we mitigate simple DoS attacks by only considering the first 72
      # characters of the password, which is also bcrypt's limit.
      password_strength = Zxcvbn.test(params[:password][0, 72])
      if password_strength.score < Rails.application.config.minimum_password_score
        account.errors.add(:password, ErrorCodes::PASSWORD_INSECURE)
      end
    end

    begin
      account.save unless account.errors.any?
    rescue ActiveRecord::RecordNotUnique
      # forgiveness is faster than permission
      account.errors.add(:username, ErrorCodes::USERNAME_TAKEN)
    end

    if account.errors.any?
      render status: :unprocessable_entity, json: JSONEnvelope.errors(account.errors)
    else
      establish_session(account.id)

      render status: :created, json: JSONEnvelope.result(
        id_token: JSON::JWT.new(
          iss: Rails.application.config.base_url,
          sub: account.id,
          aud: Rails.application.config.client_hosts[0],
          exp: Time.now.utc.to_i + Rails.application.config.auth_expiry,
          iat: Time.now.utc.to_i,
          auth_time: Time.now.utc.to_i,
        ).sign(Rails.application.config.auth_private_key, Rails.application.config.auth_signing_alg).to_s
      )
    end
  end

  # params:
  # * username
  def available
    render status: :ok, json: JSONEnvelope.result(
      available: !Account.named(params[:username]).exists?
    )
  end
end
