# Like PasswordResetter, but relies on a known account id (e.g. from the session)
class PasswordChanger
  include ActiveModel::Validations

  attr_reader :account_id, :password

  include Account::PasswordValidations
  validates :account, presence: {message: ErrorCodes::NOT_FOUND}
  validate  :account_not_locked

  def initialize(account_id, password)
    @password = password
    @account_id = account_id
  end

  def perform
    return unless valid?
    account.update(
      password: BCrypt::Password.create(password).to_s,
      require_new_password: false
    )
  end

  def account
    @account ||= Account.active.find_by_id(account_id)
  end

  private def account_not_locked
    return unless account && account.locked?
    errors.add(:account, ErrorCodes::LOCKED)
  end
end
