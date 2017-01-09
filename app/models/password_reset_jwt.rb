# TODO: switch to HMAC with another derived key
class PasswordResetJWT
  def self.generate(account_id, password_changed_at)
    new(
      iss: Rails.application.config.authn_url,
      sub: account_id,
      aud: Rails.application.config.authn_url,
      exp: Time.now.utc.to_i + Rails.application.config.password_reset_expiry,
      iat: Time.now.utc.to_i,
      scope: PasswordUpdater::SCOPE,
      lock: password_changed_at.to_i
    ).to_s
  end

  def self.decode(str)
    new(JSON::JWT.decode(str, Rails.application.config.auth_public_key))
  rescue JSON::JWT::InvalidFormat
    new({})
  end

  def initialize(claims)
    @claims = claims
  end

  def sub
    @claims[:sub]
  end

  def lock
    @claims[:lock]
  end

  def valid?
    @claims[:iss] == Rails.application.config.authn_url &&
      @claims[:aud] == Rails.application.config.authn_url &&
      @claims[:scope] == PasswordUpdater::SCOPE &&
      @claims[:exp] > Time.now.to_i
  end

  def to_s
    JSON::JWT.new(@claims)
      .sign(
        Rails.application.config.auth_private_key,
        Rails.application.config.auth_signing_alg
      ).to_s
  end
end
