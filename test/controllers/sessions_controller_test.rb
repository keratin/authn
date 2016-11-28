require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  testing '#create' do
    test 'with valid credentials' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      post sessions_path,
        params: {
          username: account.username,
          password: 'valid'
        },
        headers: TRUSTED_REFERRER

      assert_response(:created)
      assert_json_jwt(JSON.parse(response.body)['result']['id_token']) do |claims|
        assert_equal account.id, claims['sub']
      end
      assert_equal account.id, session[:account_id]
      assert_equal 'demo.dev', session[:audience]
    end

    test 'with unknown account username' do
      post sessions_path,
        params: {
          username: 'unknown',
          password: 'valid'
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('credentials' => ErrorCodes::CREDENTIALS_FAILED)
    end

    test 'with bad password' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      post sessions_path,
        params: {
          username: account.username,
          password: 'unknown'
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('credentials' => ErrorCodes::CREDENTIALS_FAILED)
    end

    test 'with untrusted referer' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      post sessions_path,
        params: {
          username: account.username,
          password: 'valid'
        },
        headers: UNTRUSTED_REFERRER

      assert_response(:forbidden)
      assert_json_errors('referer' => 'is not a trusted host')
    end
  end

  testing '#refresh' do
    test 'with existing valid session' do
      with_session(account_id: 42) do
        get refresh_sessions_path,
          headers: TRUSTED_REFERRER
      end

      assert_response(:success)
      assert_json_jwt(JSON.parse(response.body)['result']['id_token']) do |claims|
        assert_equal 42, claims['sub']
      end
    end

    test 'without existing valid session' do
      get refresh_sessions_path,
        headers: TRUSTED_REFERRER

      assert_response(:unauthorized)
    end
  end

  testing '#destroy' do
    test 'with valid session and safe redirect' do
      account_id = rand(9999)
      token = RefreshToken.create(account_id)

      with_session(account_id: account_id, token: token) do
        get logout_sessions_path,
          params: {
            redirect_uri: "https://#{Rails.application.config.application_domains.first}/callback?hello=world"
          },
          headers: TRUSTED_REFERRER
      end

      assert_response(:redirect)
      assert_redirected_to("https://#{Rails.application.config.application_domains.first}/callback?hello=world")
      refute RefreshToken.find(token)
    end

    test 'with unknown redirect' do
      get logout_sessions_path,
        params: {
          redirect_uri: 'https://evil.tech/callback'
        },
        headers: TRUSTED_REFERRER

      assert_response(:redirect)
      assert_redirected_to("https://#{Rails.application.config.application_domains.first}")
    end

    test 'with no redirect' do
      get logout_sessions_path,
        headers: TRUSTED_REFERRER

      assert_response(:redirect)
      assert_redirected_to("https://#{Rails.application.config.application_domains.first}")
    end
  end
end
