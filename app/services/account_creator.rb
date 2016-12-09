AccountCreator = Struct.new(:username, :password)
class AccountCreator
  include ActiveModel::Validations
  include Account::UsernameValidations
  include Account::PasswordValidations

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
        errors.add(:username, ErrorCodes::TAKEN)
      end
    end

    account unless errors.any?
  end
end
