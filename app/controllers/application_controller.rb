require 'json_envelope'

class ApplicationController < ActionController::API

  # a subset of the openid connect spec:
  # http://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata
  #
  # we are not 100% spec openid connect (no redirects), so not all fields apply.
  def configuration
    render status: :ok, json: {
      issuer: Rails.application.config.base_url,
      response_types_supported: ['id_token'],
      subject_types_supported: ['public'],
      id_token_signing_alg_values_supported: [Rails.application.config.auth_signing_alg],
      claims_supported: %w(iss sub aud exp iat auth_time),
      jwks_uri: app_keys_url,
    }
  end

  # the public key data necessary to validate JWT from this issuer
  # see: JWK
  def keys
    render status: :ok, json: {
      keys: [
        Rails.application.config.auth_public_key.to_jwk.slice(:kty, :kid, :e, :n).merge(
          use: 'sig',
          alg: Rails.application.config.auth_signing_alg
        )
      ]
    }
  end

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

  private def trusted_host?(uri)
    host = begin
      URI.parse(uri).host
    rescue URI::InvalidURIError
    end

    Rails.application.config.client_hosts.include?(host)
  end

  private def establish_session(account_id)
    # avoid any potential session fixation. whatever session they had before can't be trusted.
    reset_session

    session[:account_id] = account_id
    session[:created_at] = Time.now.to_i
  end

  private def issue_token_from(session)
    JSON::JWT.new(
      iss: Rails.application.config.base_url,
      sub: session[:account_id],
      aud: Rails.application.config.client_hosts[0],
      exp: Time.now.utc.to_i + Rails.application.config.auth_expiry,
      iat: Time.now.utc.to_i,
      auth_time: session[:created_at].to_i
    ).sign(Rails.application.config.auth_private_key, Rails.application.config.auth_signing_alg).to_s
  end

end
