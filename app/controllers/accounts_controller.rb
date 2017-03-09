class AccountsController < ApplicationController
  # params:
  # * username
  # * password
  def create
    raise AccessForbidden unless referred?

    creator = AccountCreator.new(params[:username], params[:password])

    if (account = creator.perform)
      establish_session(account.id, requesting_audience)

      render status: :created, json: JSONEnvelope.result(
        id_token: issue_token_from(authn_session)
      )
    else
      render status: :unprocessable_entity, json: JSONEnvelope.errors(creator.errors)
    end
  end

  # params:
  # * username: string
  # * password: string
  # * locked: boolean
  # * password_changed_at: unix timestamp
  def import
    raise AccessForbidden unless authenticated?

    importer = AccountImporter.new(params.permit('username', 'password', 'locked').to_h.symbolize_keys)

    if (account = importer.perform)
      render status: :created, json: JSONEnvelope.result(
        id: account.id
      )
    else
      render status: :unprocessable_entity, json: JSONEnvelope.errors(importer.errors)
    end
  end

  # params:
  # * username
  def available
    if Account.named(params[:username]).exists?
      render status: :unprocessable_entity, json: JSONEnvelope.errors(
        'username' => ErrorCodes::TAKEN
      )
    else
      render status: :ok, json: JSONEnvelope.result(true)
    end
  end

  # params:
  # * id
  def lock
    raise AccessUnauthenticated unless authenticated?

    if AccountLocker.new(params[:id]).perform
      head :ok
    else
      render status: :not_found, json: JSONEnvelope.errors(
        'account' => ErrorCodes::NOT_FOUND
      )
    end
  end

  # params:
  # * id
  def unlock
    raise AccessUnauthenticated unless authenticated?

    if AccountUnlocker.new(params[:id]).perform
      head :ok
    else
      render status: :not_found, json: JSONEnvelope.errors(
        'account' => ErrorCodes::NOT_FOUND
      )
    end
  end

  # params:
  # * id
  def destroy
    raise AccessUnauthenticated unless authenticated?

    if AccountArchiver.new(params[:id]).perform
      head :ok
    else
      render status: :not_found, json: JSONEnvelope.errors(
        'account' => ErrorCodes::NOT_FOUND
      )
    end
  end
end
