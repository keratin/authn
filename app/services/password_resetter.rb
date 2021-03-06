# Like PasswordChanger, but decodes a reset token to find the account
class PasswordResetter
  include ActiveModel::Validations

  attr_reader :token, :password

  include Account::PasswordValidations
  validates :account, presence: {message: ErrorCodes::NOT_FOUND}, if: ->{ token.valid? }
  validate  :account_not_locked
  validate  :token_is_valid_and_fresh

  def initialize(jwt, password)
    @password = password
    @token = PasswordResetJWT.decode(jwt)
  end

  def perform
    return unless valid?
    account.update(
      password: BCrypt::Password.create(password).to_s,
      require_new_password: false
    )
  end

  def account
    @account ||= Account.active.find_by_id(token.sub)
  end

  private def account_not_locked
    return unless account && account.locked?
    errors.add(:account, ErrorCodes::LOCKED)
  end

  private def token_is_valid_and_fresh
    return if token.valid? && (!account || token.lock == account.password_changed_at.to_i)
    errors.add(:token, ErrorCodes::INVALID_OR_EXPIRED)
  end
end
