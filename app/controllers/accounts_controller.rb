class AccountsController < ApplicationController
  # params:
  # * name
  # * password
  # * return_to
  def create
    account = Account.new(
      name: params[:name],
      password: BCrypt::Password.create(params[:password]).to_s
    )

    begin
      account.save
    rescue ActiveRecord::RecordNotUnique
      # forgiveness is faster than permission
      account.errors.add(:name, 'has already been taken')
    end

    if account.errors.any?
      render status: :unprocessable_entity, json: JSONEnvelope.errors(account.errors)
    else
      render status: :created, json: JSONEnvelope.result(account_id: account.id)
    end
  end

  # params:
  # * name
  def available
    render status: :ok, json: JSONEnvelope.result(
      available: !Account.named(params[:name]).exists?
    )
  end
end
