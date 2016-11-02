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
    rescue ActiveRecord::RecordNotUnique # forgiveness is faster than permission
      # SECURITY NOTE
      #
      # we can't entirely slough this off with a simple error because of the account confirmation system.
      #
      # account confirmation exists to fix certain two-phase commit failure modes. if there's a network
      # partition between the browser and the profile endpoint, then a signup attempt might create one but
      # not the other.
      #
      # unconfirmed accounts need to pessimistically lock the account name long enough for the signup process
      # to finish, but should not get in the way if the process fails and needs to be retried later.
      #
      # alternate versions of this strategy that attempted to find and reuse the unconfirmed account seemed
      # to be vulnerable to account takeover or account honeypot attacks. so i'm keeping it simple until one
      # of those strategies seems to be a) motivated and b) safe.
      if Account.reclaim(params[:name])
        account.save
      else
        account.errors.add(:name, 'has already been taken')
      end
    end

    if account.errors.any?
      render status: :unprocessable_entity, json: JSONEnvelope.errors(account.errors)
    else
      render status: :created, json: JSONEnvelope.result(account_id: account.id)
    end
  end

  # confirms the identified account
  #
  # returns 200 after confirming account, or if account is already confirmed
  # returns 404 if account is unknown
  def confirm
    account = Account.find_by_id(params[:id])
    if account
      account.confirm

      head :ok
    else
      head :not_found
    end
  end
end
