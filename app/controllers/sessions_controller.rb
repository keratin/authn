class SessionsController < ApplicationController
  before_action :require_trusted_referrer, only: [:create]

  # params:
  # * username
  # * password
  def create
    account_id, password = Account.named(params[:username]).pluck('id, password').first

    # SECURITY NOTE
    #
    # if no password is fetched from the database, we substitute a placeholder so that we still perform
    # the same amount of work. this mitigates timing attacks that may learn whether accounts exist by
    # checking to see how quickly this endpoint succeeds or fails.
    #
    # note that this is a low value timing attack. attackers may learn the same information more directly
    # from the signup process, which necessarily indicates whether a name is taken or not.
    placeholder = Account::EMPTY_PASSWORDS[BCrypt::Engine.cost]

    if BCrypt::Password.new(password || placeholder).is_password?(params[:password])
      establish_session(account_id)
      render status: :created, json: JSONEnvelope.result(
        id_token: JSON::JWT.new(
          iss: "https://#{request.host}",
          sub: account_id,
          aud: Rails.application.config.client_hosts[0],
          exp: Time.now.utc.to_i + Rails.application.config.auth_expiry,
          iat: Time.now.utc.to_i,
          auth_time: Time.now.utc.to_i,
        ).sign(Rails.application.config.auth_private_key, :RS256).to_s
      )
    else
      render status: :unprocessable_entity, json: JSONEnvelope.errors('credentials' => 'invalid or unknown')
    end
  end

end
