require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  testing '#edit' do
    test 'with known username' do
      password_reset_url = Rails.application.config.application_endpoints[:password_reset_uri].to_s
      stub_request(:post, password_reset_url)

      account = FactoryGirl.create(:account)

      cors_get password_reset_path,
        params: {
          username: account.username
        },
        headers: TRUSTED_REFERRER

      assert_response(:success)
      assert_requested(:post, password_reset_url) do |req|
        assert req.body.include?("account_id=#{account.id}")
        assert req.body.include?('token=')
      end
    end

    test 'with unknown username' do
      cors_get password_reset_path,
        params: {
          username: 'unknown'
        },
        headers: TRUSTED_REFERRER

      assert_response(:success)
    end

    test 'with locked account' do
      account = FactoryGirl.create(:account, :locked)

      cors_get password_reset_path,
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

      cors_post password_path,
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

      cors_post password_path,
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

      cors_post password_path,
        params: {
          token: jwt(account, exp: 1.hour.ago),
          password: SecureRandom.hex(8)
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('token' => ErrorCodes::INVALID_OR_EXPIRED)
    end

    test 'with valid token and weak password' do
      account = FactoryGirl.create(:account)

      cors_post password_path,
        params: {
          token: jwt(account),
          password: 'password'
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('password' => ErrorCodes::INSECURE)
    end

    test 'with session and password' do
      account = FactoryGirl.create(:account)
      password = SecureRandom.hex(8)

      with_session(account_id: account.id) do
        cors_post password_path,
          params: {
            password: password
          },
          headers: TRUSTED_REFERRER

        assert_response(:success)
        assert account.reload.authenticate(password)
      end
    end

    test 'with session and weak password' do
      account = FactoryGirl.create(:account)

      with_session(account_id: account.id) do
        cors_post password_path,
          params: {
            password: 'password'
          },
          headers: TRUSTED_REFERRER

        assert_response(:unprocessable_entity)
        assert_json_errors('password' => ErrorCodes::INSECURE)
      end
    end

    test 'with session and token and password' do
      session_account = FactoryGirl.create(:account)
      token_account = FactoryGirl.create(:account)
      password = SecureRandom.hex(8)

      with_session(account_id: session_account.id) do
        cors_post password_path,
          params: {
            token: jwt(token_account),
            password: password
          },
          headers: TRUSTED_REFERRER

        assert_response(:success)
        assert token_account.reload.authenticate(password)
        refute session_account.reload.authenticate(password)
      end
    end
  end

  private def jwt(account, claim_overrides = {})
    PasswordResetJWT.new({
      iss: Rails.application.config.authn_url,
      sub: account.id,
      aud: Rails.application.config.authn_url,
      exp: Time.now.utc.to_i + Rails.application.config.password_reset_expiry,
      iat: Time.now.utc.to_i,
      scope: PasswordResetJWT::SCOPE,
      lock: account.password_changed_at.to_i
    }.merge(claim_overrides))
      .to_s
  end
end
