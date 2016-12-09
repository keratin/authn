AccountCreator = Struct.new(:username, :password)
class AccountCreator
  include ActiveModel::Validations

  validates :username, presence: { message: ErrorCodes::USERNAME_MISSING }
  validate  :username_format
  validates :password, presence: { message: ErrorCodes::PASSWORD_MISSING }
  validate  :password_strength

  # either returns an account or registers errors
  def perform
    # account = nil # scope

    if valid?
      begin
        account = Account.create(
          username: username,
          password: BCrypt::Password.create(password).to_s
        )
      rescue ActiveRecord::RecordNotUnique
        # forgiveness is faster than permission
        errors.add(:username, ErrorCodes::USERNAME_TAKEN)
      end
    end

    account unless errors.any?
  end

  private def password_strength
    if password.present? && PasswordScorer.new(password).perform < Rails.application.config.minimum_password_score
      errors.add(:password, ErrorCodes::PASSWORD_INSECURE)
    end
  end

  # worried about an imperfect regex? see: http://www.regular-expressions.info/email.html
  #
  # SECURITY NOTE: if someone can flood the system with usernames in excess of a megabyte, they
  # might be able to ddoss a bad regex. in my simple tests, a similar regex without character limits
  # could take up to 1000ms on a 100_000_000 character username. adding character limits brings that
  # time down to around 50ms.
  EMAIL = /\A[A-Z0-9._%+-]{1,64}@(?:[A-Z0-9-]{1,63}\.){1,125}[A-Z]{2,63}\z/i

  private def username_format
    return if username.blank?

    if Rails.application.config.email_usernames
      errors.add(:username, ErrorCodes::FORMAT) unless username =~ EMAIL
    elsif username.length < Account::USERNAME_MIN_LENGTH
      errors.add(:username, ErrorCodes::FORMAT)
    end
  end
end
