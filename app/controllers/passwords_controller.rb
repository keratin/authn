class PasswordsController < ApplicationController
  # params:
  # * username
  def edit
    raise AccessForbidden unless referred?

    if account = Account.named(params[:username]).take
      # SECURITY NOTE:
      #
      # using a background job will:
      # * insulate the user from back channel network request overhead
      # * protect this endpoint from user enumeration timing attacks
      SendResetTokenJob.perform_async(account) unless account.locked?
    end

    # no user enumeration at this endpoint
    head :ok
  end

  # params:
  # * token
  # * password
  def update
    raise AccessForbidden unless referred?

    if params[:token]
      updater = PasswordResetter.new(params[:token], params[:password])
    else
      account_id = RefreshToken.find(authn_session[:sub])
      updater = PasswordChanger.new(account_id, params[:password])
    end

    if updater.perform
      establish_session(updater.account.id, requesting_audience)

      render status: :created, json: JSONEnvelope.result(
        id_token: issue_token_from(authn_session)
      )
    else
      render status: :unprocessable_entity, json: JSONEnvelope.errors(updater.errors)
    end
  end
end
