require 'test_helper'

class IdentityJWTTest < ActiveSupport::TestCase
  testing '.generate' do
    test 'includes KID claim' do
      session = {
        iss: 'foo',
        sub: RefreshToken.create(0),
        azp: 'bar',
        iat: Time.now.to_i
      }

      jwt = JSON::JWT.decode(IdentityJWT.generate(session), :skip_verification)
      assert jwt.kid.present?
      assert_equal Rails.application.config.key_provider.key.to_jwk[:kid], jwt.kid
    end
  end
end
