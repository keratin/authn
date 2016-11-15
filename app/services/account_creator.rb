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

  private def password_strength
    if password.present? && PasswordScorer.new(password).perform < Rails.application.config.minimum_password_score
      errors.add(:password, ErrorCodes::PASSWORD_INSECURE)
    end
  end
end
