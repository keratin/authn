class AccountsController < ApplicationController
  before_action :require_trusted_referrer, only: [:create]
  before_action :require_api_credentials, only: [:lock, :unlock, :destroy]

  # params:
  # * username
  # * password
  def create
    creator = AccountCreator.new(params[:username], params[:password])

    if account = creator.perform
      establish_session(account.id, requesting_audience)

      render status: :created, json: JSONEnvelope.result(
        id_token: issue_token_from(session)
      )
    else
      render status: :unprocessable_entity, json: JSONEnvelope.errors(creator.errors)
    end
  end

  # params:
  # * username
  def available
    if Account.named(params[:username]).exists?
      render status: :unprocessable_entity, json: JSONEnvelope.errors(
        'username' => ErrorCodes::USERNAME_TAKEN
      )
    else
      render status: :ok, json: JSONEnvelope.result(true)
    end
  end

  # params:
  # * id
  def lock
    if AccountLocker.new(params[:id]).perform
      head :ok
    else
      render status: :not_found, json: JSONEnvelope.errors(
        'account' => ErrorCodes::ACCOUNT_NOT_FOUND
      )
    end
  end

  # params:
  # * id
  def unlock
    if AccountUnlocker.new(params[:id]).perform
      head :ok
    else
      render status: :not_found, json: JSONEnvelope.errors(
        'account' => ErrorCodes::ACCOUNT_NOT_FOUND
      )
    end
  end

  # params:
  # * id
  def destroy
    if AccountArchiver.new(params[:id]).perform
      head :ok
    else
      head :not_found
    end
  end
end
