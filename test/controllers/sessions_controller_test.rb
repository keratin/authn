require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  testing '#create' do
    test 'with valid credentials' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      assert_cors(:post, session_path)
      post session_path,
        params: {
          username: account.username,
          password: 'valid'
        },
        headers: TRUSTED_REFERRER

      assert_response(:created)
      assert_json_jwt(JSON.parse(response.body)['result']['id_token']) do |claims|
        assert_equal account.id, claims['sub']
      end

      authn_session.tap do |session|
        assert_equal account.id, RefreshToken.find(session[:sub])
        assert_equal Rails.application.config.authn_url, session[:aud]
        assert_equal Rails.application.config.application_domains.first, session[:azp]
      end
    end

    test 'with empty credentials' do
      post session_path,
        params: {
          username: '',
          password: ''
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('credentials' => ErrorCodes::FAILED)
    end

    test 'with locked credentials' do
      account = FactoryGirl.create(:account, :locked, clear_password: 'valid')

      post session_path,
        params: {
          username: account.username,
          password: 'valid'
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('account' => ErrorCodes::LOCKED)
    end

    test 'with inactive password' do
      account = FactoryGirl.create(:account, clear_password: 'valid', require_new_password: true)

      post session_path,
        params: {
          username: account.username,
          password: 'valid'
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('credentials' => ErrorCodes::EXPIRED)
    end

    test 'with unknown account username' do
      post session_path,
        params: {
          username: 'unknown',
          password: 'valid'
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('credentials' => ErrorCodes::FAILED)
    end

    test 'with bad password' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      post session_path,
        params: {
          username: account.username,
          password: 'unknown'
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('credentials' => ErrorCodes::FAILED)
    end

    test 'with untrusted referer' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      post session_path,
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
        assert_cors(:get, refresh_session_path)
        get refresh_session_path,
          headers: TRUSTED_REFERRER
      end

      assert_response(:success)
      assert_json_jwt(JSON.parse(response.body)['result']['id_token']) do |claims|
        assert_equal 42, claims['sub']
      end
    end

    test 'without existing valid session' do
      get refresh_session_path,
        headers: TRUSTED_REFERRER

      assert_response(:unauthorized)
    end

    test 'with mangled session cookie' do
      get refresh_session_path,
        headers: TRUSTED_REFERRER.merge(
          'Cookie' => "#{AuthNSession::NAME}=\"invalid\""
        )

      assert_response(:unauthorized)
    end

    test 'with JWT-ish session cookie' do
      get refresh_session_path,
        headers: TRUSTED_REFERRER.merge(
          'Cookie' => "#{AuthNSession::NAME}=\"e30=.e30=.abc\""
        )

      assert_response(:unauthorized)
    end
  end

  testing '#destroy' do
    test 'with valid session' do
      account_id = rand(9999)
      token = RefreshToken.create(account_id)

      with_session(account_id: account_id, token: token) do
        assert_cors(:delete, session_path)
        delete session_path,
          headers: TRUSTED_REFERRER
      end

      assert_response(:ok)
      refute RefreshToken.find(token)
    end
  end
end
