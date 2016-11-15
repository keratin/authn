class PasswordUpdater
  SCOPE = 'reset'
  include ActiveModel::Validations

  attr_reader :token, :password

  validates :password, presence: { message: ErrorCodes::PASSWORD_MISSING }
  validate  :password_strength
  validate  :token_is_valid_and_fresh

  def initialize(jwt, password)
    @password = password
    @token = begin
      JSON::JWT.decode(jwt, Rails.application.config.auth_public_key)
    rescue JSON::JWT::InvalidFormat
      {}
    end
  end

  def perform
    if valid?
      account.update(password: BCrypt::Password.create(password).to_s)
    end
  end

  def account
    @account ||= Account.find(token[:sub])
  end

  private def token_is_valid_and_fresh
    if token[:iss] != Rails.application.config.base_url ||
      token[:aud] != Rails.application.config.base_url ||
      token[:scope] != PasswordUpdater::SCOPE ||
      token[:exp] <= Time.now.to_i ||
      token[:lock] != account.password_changed_at.to_i

      errors.add(:token, ErrorCodes::TOKEN_INVALID_OR_EXPIRED)
    end
  end

  private def password_strength
    if password.present? && PasswordScorer.new(password).perform < Rails.application.config.minimum_password_score
      errors.add(:password, ErrorCodes::PASSWORD_INSECURE)
    end
  end
end
