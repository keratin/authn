class SessionsController < ApplicationController
  before_action :require_trusted_referrer, only: [:create, :refresh]

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
        id_token: issue_token_from(session)
      )
    else
      render status: :unprocessable_entity, json: JSONEnvelope.errors('credentials' => ErrorCodes::CREDENTIALS_FAILED)
    end
  end

  def refresh
    if session[:account_id]
      render status: :created, json: JSONEnvelope.result(
        id_token: issue_token_from(session)
      )
    else
      render status: :unauthorized
    end
  end

end
