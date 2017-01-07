class ApplicationController < ActionController::API
  include AccessControl
  include ActionController::Cookies

  AUTHN_SESSION_NAME = 'authn'

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
    RefreshToken.revoke(authn_session[:token]) if authn_session[:token]

    # NOTE: this cookie is not set to expire, but the refresh token is.
    cookies[AUTHN_SESSION_NAME] = {
      value: JSON::JWT.new(
        iss: Rails.application.config.authn_url,
        sub: account_id,
        aud: Rails.application.config.authn_url,
        iat: Time.now.utc.to_i,
        azp: audience,
        token: RefreshToken.create(account_id)
      ).sign(Rails.application.config.session_key, 'HS256').to_s,
      secure: Rails.application.config.force_ssl,
      httponly: true
    }
  end

  private def authn_session
    return {} unless cookies[AUTHN_SESSION_NAME].present?

    @authn_session ||= JSON::JWT.decode(cookies[AUTHN_SESSION_NAME], Rails.application.config.session_key) || {}
  end

  private def issue_token_from(sess)
    ActivesTracker.new(sess[:sub]).perform

    JSON::JWT.new(
      iss: sess[:iss],
      sub: sess[:sub],
      aud: sess[:azp],
      exp: Time.now.utc.to_i + Rails.application.config.access_token_expiry,
      iat: Time.now.utc.to_i,
      auth_time: sess[:iat]
    ).sign(Rails.application.config.auth_private_key, Rails.application.config.auth_signing_alg).to_s
  end

end
