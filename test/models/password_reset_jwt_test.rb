require 'test_helper'

class PasswordResetJWTTest < ActiveSupport::TestCase
  testing '.generate' do
    test 'returns signed JWT string' do
      jwt = PasswordResetJWT.generate(rand(999), Time.now.to_i)
      assert jwt.is_a?(String)
      assert_equal 3, jwt.split('.').reject(&:blank?).count
    end
  end

  testing '.decode' do
    test 'returns PasswordResetJWT' do
      account_id = rand(999)
      time = Time.now.to_i

      token = PasswordResetJWT.generate(account_id, time)
      val = PasswordResetJWT.decode(token)
      assert val.is_a?(PasswordResetJWT)
      assert_equal account_id, val.sub
      assert_equal time, val.lock
    end
  end

  testing '#valid?' do
    test 'with expected claims' do
      assert jwt.valid?
    end

    test 'with unknown issuer' do
      refute jwt(iss: 'https://unknown.tech').valid?
    end

    test 'with unknown audience' do
      refute jwt(aud: 'https://unknown.tech').valid?
    end

    test 'with unknown scope' do
      refute jwt(scope: 'UNKNOWN').valid?
    end

    test 'after expiration' do
      refute jwt(exp: 1.hour.ago).valid?
    end
  end

  def jwt(claim_overrides = {})
    PasswordResetJWT.new({
      iss: Rails.application.config.authn_url,
      sub: rand(999),
      aud: Rails.application.config.authn_url,
      exp: Time.now.utc.to_i + Rails.application.config.password_reset_expiry,
      iat: Time.now.utc.to_i,
      scope: PasswordResetJWT::SCOPE,
      lock: Time.now.utc.to_i
    }.merge(claim_overrides))
  end
end
