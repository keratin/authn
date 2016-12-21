class ApplicationController < ActionController::API
  include AccessControl

  # Unauthenticated access means credentials are required but absent. It should map to the HTTP 401
  # status code.
  class AccessUnauthenticated < StandardError; end
  # Forbidden access means credentials are insufficient. It should map to the HTTP 403 status code.
  class AccessForbidden < StandardError; end

  rescue_from AccessForbidden do |exception|
    render status: :forbidden, json: JSONEnvelope.errors('referer' => 'is not a trusted host')
  end

  rescue_from AccessUnauthenticated do |exception|
    ActionController::HttpAuthentication::Basic.authentication_request(self, "Application", nil)
  end

  private def requesting_audience
    URI.parse(request.referer).host
  rescue URI::InvalidURIError
    nil
  end

  private def establish_session(account_id, audience)
    # avoid any potential session fixation. whatever session they had before can't be trusted.
    RefreshToken.revoke(session[:token]) if session[:token]
    reset_session

    session[:account_id] = account_id
    session[:audience] = audience
    session[:token] = RefreshToken.create(account_id)
    session[:created_at] = Time.now.to_i
  end

  private def issue_token_from(session)
    ActivesTracker.new(session[:account_id]).perform

    JSON::JWT.new(
      iss: Rails.application.config.authn_url,
      sub: session[:account_id],
      aud: session[:audience],
      exp: Time.now.utc.to_i + Rails.application.config.access_token_expiry,
      iat: Time.now.utc.to_i,
      auth_time: session[:created_at].to_i
    ).sign(Rails.application.config.auth_private_key, Rails.application.config.auth_signing_alg).to_s
  end

end
