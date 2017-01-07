class ApplicationController < ActionController::API
  include AccessControl
  include AuthNSession

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

  private def issue_token_from(sess)
    ActivesTracker.new(sess[:sub]).perform

    JSON::JWT.new(
      iss: sess[:iss],
      sub: RefreshToken.find(sess[:sub]),
      aud: sess[:azp],
      exp: Time.now.utc.to_i + Rails.application.config.access_token_expiry,
      iat: Time.now.utc.to_i,
      auth_time: sess[:iat]
    ).sign(Rails.application.config.auth_private_key, Rails.application.config.auth_signing_alg).to_s
  end

end
