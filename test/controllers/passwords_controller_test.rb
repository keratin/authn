require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  testing '#edit' do
    test 'with known username' do
      password_reset_url = Rails.application.config.application_endpoints[:password_reset_uri].to_s
      stub_request(:post, password_reset_url)

      account = FactoryGirl.create(:account)

      get edit_password_path,
        params: {
          username: account.username
        },
        headers: TRUSTED_REFERRER

      assert_response(:success)
      assert_requested(:post, password_reset_url) do |req|
        assert req.body.include?("account_id=#{account.id}")
        assert req.body.include?("token=")
      end
    end

    test 'with unknown username' do
      get edit_password_path,
        params: {
          username: 'unknown'
        },
        headers: TRUSTED_REFERRER

      assert_response(:success)
    end

    test 'with locked account' do
      account = FactoryGirl.create(:account, :locked)

      get edit_password_path,
        params: {
          username: account.username
        },
        headers: TRUSTED_REFERRER

      assert_response(:success)
    end
  end

  testing '#update' do
    test 'with valid token and password' do
      account = FactoryGirl.create(:account)
      password = SecureRandom.hex(8)

      patch password_path,
        params: {
          token: jwt(account),
          password: password
        },
        headers: TRUSTED_REFERRER

      assert_response(:success)
      assert account.reload.authenticate(password)
      assert_json_jwt(JSON.parse(response.body)['result']['id_token']) do |claims|
        assert_equal account.id, claims['sub']
      end

      authn_session.tap do |session|
        assert_equal account.id, RefreshToken.find(session[:sub])
        assert_equal Rails.application.config.authn_url, session[:aud]
        assert_equal Rails.application.config.application_domains.first, session[:azp]
      end
    end

    test 'with invalid token' do
      account = FactoryGirl.create(:account)

      patch password_path,
        params: {
          token: jwt(account, scope: 'OTHER'),
          password: SecureRandom.hex(8)
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('token' => ErrorCodes::INVALID_OR_EXPIRED)
    end

    test 'with expired token' do
      account = FactoryGirl.create(:account)

      patch password_path,
        params: {
          token: jwt(account, exp: 1.hour.ago),
          password: SecureRandom.hex(8)
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('token' => ErrorCodes::INVALID_OR_EXPIRED)
    end

    test 'with weak password' do
      account = FactoryGirl.create(:account)

      patch password_path,
        params: {
          token: jwt(account),
          password: 'password'
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('password' => ErrorCodes::INSECURE)
    end
  end

  private def jwt(account, claim_overrides = {})
    claims = {
      iss: Rails.application.config.authn_url,
      sub: account.id,
      aud: Rails.application.config.authn_url,
      exp: Time.now.utc.to_i + Rails.application.config.password_reset_expiry,
      iat: Time.now.utc.to_i,
      scope: PasswordUpdater::SCOPE,
      lock: account.password_changed_at.to_i
    }.merge(claim_overrides)
    JSON::JWT.new(claims).sign(Rails.application.config.auth_private_key, Rails.application.config.auth_signing_alg).to_s
  end
end
