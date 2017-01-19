# Like PasswordChanger, but decodes a reset token to find the account
class PasswordResetter
  SCOPE = 'reset'
  include ActiveModel::Validations

  attr_reader :token, :password

  include Account::PasswordValidations
  validates :account, presence: { message: ErrorCodes::NOT_FOUND }, if: ->{ token.valid? }
  validate  :account_not_locked
  validate  :token_is_valid_and_fresh

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
    @account ||= Account.active.find_by_id(token.sub)
  end

  private def account_not_locked
    if account && account.locked?
      errors.add(:account, ErrorCodes::LOCKED)
    end
  end

  private def token_is_valid_and_fresh
    unless token.valid? &&
      (!account || token.lock == account.password_changed_at.to_i)

      errors.add(:token, ErrorCodes::INVALID_OR_EXPIRED)
    end
  end
end
