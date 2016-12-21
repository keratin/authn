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

    if BCrypt::Password.new(account.try(&:password) || placeholder).is_password?(params[:password])
      if account.locked?
        render status: :unprocessable_entity, json: JSONEnvelope.errors('account' => ErrorCodes::LOCKED)
      else
        establish_session(account.id, requesting_audience)
        render status: :created, json: JSONEnvelope.result(
          id_token: issue_token_from(session)
        )
      end
    else
      render status: :unprocessable_entity, json: JSONEnvelope.errors('credentials' => ErrorCodes::FAILED)
    end
  end

  def refresh
    raise AccessForbidden unless referred?

    if session[:account_id] && RefreshToken.find(session[:token])
      RefreshToken.touch(token: session[:token], account_id: session[:account_id])
      render status: :created, json: JSONEnvelope.result(
        id_token: issue_token_from(session)
      )
    else
      render status: :unauthorized
    end
  end

  # params:
  # * redirect_uri (optional)
  def destroy
    raise AccessForbidden unless referred?

    RefreshToken.revoke(session[:token])
    reset_session

    redirect_host = begin
      URI.parse(params[:redirect_uri]).host
    rescue URI::InvalidURIError
      nil
    end

    if Rails.application.config.application_domains.include?(redirect_host)
      redirect_to params[:redirect_uri]
    else
      redirect_to request.referer
    end
  end

end
