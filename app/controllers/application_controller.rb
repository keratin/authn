require 'json_envelope'

class ApplicationController < ActionController::API
  # when HTTP_REFERER exists, it's a great way to prevent CSRF attacks.
  #
  # an experiment performed in http://seclab.stanford.edu/websec/csrf/csrf.pdf found the
  # header existed for 99.9% of users over HTTPS, even cross-origin. the header appears
  # to be primarily suppressed at the network level, not the user agent.
  #
  # if this is ever determined insufficient, the backup plan is a custom header set by
  # compatible javascript. stay stateless!
  private def require_trusted_referrer
    return if trusted_host?(request.referer)
    render status: :forbidden, json: JSONEnvelope.errors('referer' => 'is not a trusted host')
  end

  private def require_api_credentials
    auth_strategy = ActionController::HttpAuthentication::Basic

    # SECURITY NOTE
    #
    # beware timing attacks! we must not only compare username and password securely to avoid hints
    # about partial matches, we must also be sure to compare both each time and avoid giving away
    # a correct guess on the username.
    authorized = auth_strategy.authenticate(request) do |username, password|
      [
        SecureCompare.compare(username, Rails.application.config.api_username),
        SecureCompare.compare(password, Rails.application.config.api_password)
      ].all?
    end

    auth_strategy.authentication_request(self, "Application", nil) unless authorized
  end

  private def trusted_host?(uri)
    host = begin
      URI.parse(uri).host
    rescue URI::InvalidURIError
    end

    Rails.application.config.application_domains.include?(host)
  end

  private def establish_session(account_id)
    # avoid any potential session fixation. whatever session they had before can't be trusted.
    RefreshToken.revoke(session[:token]) if session[:token]
    reset_session

    session[:account_id] = account_id
    session[:token] = RefreshToken.create(account_id)
    session[:created_at] = Time.now.to_i
  end

  private def issue_token_from(session)
    ActivesTracker.new(session[:account_id]).perform

    JSON::JWT.new(
      iss: Rails.application.config.authn_url,
      sub: session[:account_id],
      aud: Rails.application.config.application_domains[0],
      exp: Time.now.utc.to_i + Rails.application.config.access_token_expiry,
      iat: Time.now.utc.to_i,
      auth_time: session[:created_at].to_i
    ).sign(Rails.application.config.auth_private_key, Rails.application.config.auth_signing_alg).to_s
  end

end
