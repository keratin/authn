module SessionJWT
  def self.generate(account_id, azp)
    JSON::JWT.new(
      iss: Rails.application.config.authn_url,
      sub: RefreshToken.create(account_id),
      aud: Rails.application.config.authn_url,
      iat: Time.now.utc.to_i,
      azp: azp
    ).sign(Rails.application.config.session_key, 'HS256').to_s
  end

  def self.decode(str)
    return {} if str.blank?
    JSON::JWT.decode(str, Rails.application.config.session_key) || {}
  rescue JSON::JWT::Exception
    {}
  end
end
