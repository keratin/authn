class AccountImporter
  include ActiveModel::Validations
  validates :username, presence: {message: ErrorCodes::MISSING}
  validates :password, presence: {message: ErrorCodes::MISSING}

  attr_reader :username
  attr_reader :password
  attr_reader :locked

  def initialize(username: nil, password: nil, locked: false)
    @username = username
    @password = password
    @locked = locked
  end

  # either returns an account or registers errors
  def perform
    if valid?
      begin
        account = Account.create(
          username: username,
          password: crypted_password,
          locked: locked
        )
      rescue ActiveRecord::RecordNotUnique
        # forgiveness is faster than permission
        errors.add(:username, ErrorCodes::TAKEN)
      end
    end

    account unless errors.any?
  end

  private def crypted_password
    @crypted_password ||= bcrypt?(password) ? password : BCrypt::Password.create(password).to_s
  end

  private def bcrypt?(str)
    !!str.match(/\A\$2[ayb]\$[0-9]{2}\$[A-Za-z0-9\.\/]{53}\z/)
  end
end
