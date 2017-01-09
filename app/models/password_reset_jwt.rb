module PasswordResetJWT
  # TODO: switch to HMAC with another derived key
  def self.generate(account_id, password_changed_at)
    JSON::JWT.new(
      iss: Rails.application.config.authn_url,
      sub: account_id,
      aud: Rails.application.config.authn_url,
      exp: Time.now.utc.to_i + Rails.application.config.password_reset_expiry,
      iat: Time.now.utc.to_i,
      scope: PasswordUpdater::SCOPE,
      lock: password_changed_at.to_i
    ).sign(Rails.application.config.auth_private_key, Rails.application.config.auth_signing_alg).to_s
  end

  def self.decode(str)
    JSON::JWT.decode(str, Rails.application.config.auth_public_key)
  rescue JSON::JWT::InvalidFormat
    {}
  end
end
