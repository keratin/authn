class PasswordsController < ApplicationController
  before_action :require_trusted_referrer

  # params:
  # * username
  def edit
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
    updater = PasswordUpdater.new(params[:token], params[:password])

    if updater.perform
      establish_session(updater.account.id, requesting_audience)

      render status: :created, json: JSONEnvelope.result(
        id_token: issue_token_from(session)
      )
    else
      render status: :unprocessable_entity, json: JSONEnvelope.errors(updater.errors)
    end
  end
end
