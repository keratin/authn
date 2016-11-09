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
        assert_equal 1, claims['sub']
      end
      assert_equal 1, session[:account_id]
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
end
