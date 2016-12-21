class MetadataController < ApplicationController
  # a subset of the openid connect spec:
  # http://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata
  #
  # we are not 100% spec openid connect (no redirects), so not all fields apply.
  def configuration
    render status: :ok, json: {
      issuer: Rails.application.config.authn_url,
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

  def stats
    raise AccessUnauthorized unless authenticated?

    render status: :ok, json: {
      actives: ActivesReporter.new.perform,
    }
  end
end
