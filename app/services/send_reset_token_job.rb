class SendResetTokenJob
  include SuckerPunch::Job

  def perform(account)
    Net::HTTP.post_form(
      Rails.application.config.application_endpoints[:password_reset_uri],
      account_id: account.id,
      token: PasswordResetJWT.generate(account.id, account.password_changed_at)
    )
  end
end
