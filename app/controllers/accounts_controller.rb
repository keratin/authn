class AccountsController < ApplicationController
  before_action :require_trusted_referrer, only: [:create]

  # params:
  # * username
  # * password
  # * return_to
  def create
    account = Account.new(
      username: params[:username],
      password: BCrypt::Password.create(params[:password]).to_s
    )

    begin
      account.save
    rescue ActiveRecord::RecordNotUnique
      # forgiveness is faster than permission
      account.errors.add(:username, 'has already been taken')
    end

    if account.errors.any?
      render status: :unprocessable_entity, json: JSONEnvelope.errors(account.errors)
    else
      establish_session(account.id)
      render status: :created, json: JSONEnvelope.result()
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
