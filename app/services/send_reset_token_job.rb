class SendResetTokenJob
  include SuckerPunch::Job

  def perform(account)
    reset_token = JSON::JWT.new(
      iss: Rails.application.config.base_url,
      sub: account.id,
      aud: Rails.application.config.base_url,
      exp: Time.now.utc.to_i + Rails.application.config.password_reset_expiry,
      iat: Time.now.utc.to_i,
      scope: PasswordUpdater::SCOPE,
      lock: account.password_changed_at.to_i
    ).sign(Rails.application.config.auth_private_key, Rails.application.config.auth_signing_alg).to_s

    Net::HTTP.post_form(Rails.application.config.application_endpoints[:password_reset_uri],
      account_id: account.id,
      token: reset_token
    )
  end
end
