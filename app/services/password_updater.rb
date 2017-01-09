class PasswordUpdater
  SCOPE = 'reset'
  include ActiveModel::Validations
  include Account::PasswordValidations

  attr_reader :token, :password

  validate  :token_is_valid_and_fresh
  validates :account, presence: { message: ErrorCodes::NOT_FOUND }
  validate  :account_not_locked

  def initialize(jwt, password)
    @password = password
    @token = PasswordResetJWT.decode(jwt)
  end

  def perform
    if valid?
      account.update(password: BCrypt::Password.create(password).to_s)
    end
  end

  def account
    @account ||= Account.active.find_by_id(token[:sub])
  end

  # TODO: move into PasswordResetJWT instance
  private def token_is_valid_and_fresh
    if token[:iss] != Rails.application.config.authn_url ||
      token[:aud] != Rails.application.config.authn_url ||
      token[:scope] != PasswordUpdater::SCOPE ||
      token[:exp] <= Time.now.to_i ||
      (account && token[:lock] != account.password_changed_at.to_i)

      errors.add(:token, ErrorCodes::INVALID_OR_EXPIRED)
    end
  end

  private def account_not_locked
    if account && account.locked?
      errors.add(:account, ErrorCodes::LOCKED)
    end
  end
end
