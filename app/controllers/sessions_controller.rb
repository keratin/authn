class SessionsController < ApplicationController
  # params:
  # * username
  # * password
  def create
    raise AccessForbidden unless referred?

    account = Account.named(params[:username]).first

    # SECURITY NOTE
    #
    # if no password is fetched from the database, we substitute a placeholder so that we still perform
    # the same amount of work. this mitigates timing attacks that may learn whether accounts exist by
    # checking to see how quickly this endpoint succeeds or fails.
    #
    # note that this is a low value timing attack. attackers may learn the same information more directly
    # from the signup process, which necessarily indicates whether a name is taken or not.
    placeholder = Account::EMPTY_PASSWORDS[BCrypt::Engine.cost]

    if BCrypt::Password.new(account.try(&:password) || placeholder).is_password?(params[:password]) && params[:password].present?
      if account.locked?
        render status: :unprocessable_entity, json: JSONEnvelope.errors('account' => ErrorCodes::LOCKED)
      elsif account.require_new_password?
        render status: :unprocessable_entity, json: JSONEnvelope.errors('credentials' => ErrorCodes::EXPIRED)
      else
        establish_session(account.id, requesting_audience)
        render status: :created, json: JSONEnvelope.result(
          id_token: issue_token_from(authn_session)
        )
      end
    else
      render status: :unprocessable_entity, json: JSONEnvelope.errors('credentials' => ErrorCodes::FAILED)
    end
  end

  def refresh
    raise AccessForbidden unless referred?

    if (account_id = RefreshToken.find(authn_session[:sub]))
      RefreshToken.touch(token: authn_session[:sub], account_id: account_id)
      render status: :created, json: JSONEnvelope.result(
        id_token: issue_token_from(authn_session)
      )
    else
      render status: :unauthorized
    end
  end

  def destroy
    raise AccessForbidden unless referred?

    RefreshToken.revoke(authn_session[:sub])
    cookies.delete(AuthNSession::NAME)

    head :ok
  end
end
