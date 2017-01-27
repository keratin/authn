module IdentityJWT
  def self.generate(session)
    JSON::JWT.new(
      iss: session[:iss],
      sub: RefreshToken.find(session[:sub]),
      aud: session[:azp],
      exp: Time.now.utc.to_i + Rails.application.config.access_token_expiry,
      iat: Time.now.utc.to_i,
      auth_time: session[:iat]
    ).sign(Rails.application.config.key_provider.key.to_jwk, Rails.application.config.auth_signing_alg).to_s
  end
end
