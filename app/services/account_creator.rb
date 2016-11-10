AccountCreator = Struct.new(:username, :password) do
  include ActiveModel::Validations

  validates :username, presence: { message: ErrorCodes::USERNAME_MISSING }
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

  # SECURITY NOTE:
  #
  # this password complexity algorithm is expensive and scales exponentially to the length
  # of the provided string. we mitigate simple DoS attacks by only considering the first 72
  # characters of the password, which is also bcrypt's limit.
  def password_score
    return 0 unless password.present?
    @score ||= Zxcvbn.test(password[0, 72]).score
  end

  private def password_strength
    if password.present? && password_score < Rails.application.config.minimum_password_score
      errors.add(:password, ErrorCodes::PASSWORD_INSECURE)
    end
  end
end
