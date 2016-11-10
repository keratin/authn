class AccountsController < ApplicationController
  before_action :require_trusted_referrer, only: [:create]

  # params:
  # * username
  # * password
  def create
    creator = AccountCreator.new(params[:username], params[:password])

    if account = creator.perform
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
    else
      render status: :unprocessable_entity, json: JSONEnvelope.errors(creator.errors)
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
