require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  testing '#create' do
    test 'with username and password' do
      post accounts_path,
        params: {
          username: 'username',
          password: 'secret'
        },
        headers: TRUSTED_REFERRER

      assert_response :created
      assert_json_jwt(JSON.parse(response.body)['result']['id_token']) do |claims|
        assert_equal 1, claims['sub']
      end
      assert_equal 1, session[:account_id]
    end

    test 'with missing fields' do
      post accounts_path,
        params: {},
        headers: TRUSTED_REFERRER

      assert_response :unprocessable_entity
      assert_json_errors(
        'username' => ErrorCodes::USERNAME_MISSING,
        'password' => ErrorCodes::PASSWORD_MISSING
      )
    end

    test 'with insecure password' do
      post accounts_path,
        params: {
          username: 'username',
          password: 'insecure'
        },
        headers: TRUSTED_REFERRER

      assert_response :unprocessable_entity
      assert_json_errors('password' => PASSWORD_INSECURE)
    end

    test 'with username of existing account' do
      account = FactoryGirl.create(:account)

      post accounts_path,
        params: {
          username: account.username,
          password: 'new password'
        },
        headers: TRUSTED_REFERRER

      assert_response :unprocessable_entity
      assert_json_errors('username' => ErrorCodes::USERNAME_TAKEN)
    end

    test 'with untrusted referrer' do
      post accounts_path,
        params: {
          username: 'username',
          password: 'secret'
        },
        headers: UNTRUSTED_REFERRER

      assert_response :forbidden
      assert_json_errors('referer' => 'is not a trusted host')
    end
  end

  testing '#available' do
    test 'with unknown username' do
      get available_accounts_path,
        params: {
          username: 'unknown'
        }

      assert_response :success
      assert_json_result('available' => true)
    end

    test 'with existing username' do
      account = FactoryGirl.create(:account)

      get available_accounts_path,
        params: {
          username: account.username
        }

      assert_response :success
      assert_json_result('available' => false)
    end
  end
end
