require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  testing '#create' do
    test 'with username and password' do
      account_id = Account.maximum(:id).to_i + 1

      post accounts_path,
        params: {
          username: 'username',
          password: SecureRandom.hex(8)
        },
        headers: TRUSTED_REFERRER

      assert_response :created
      assert_json_jwt(JSON.parse(response.body)['result']['id_token']) do |claims|
        assert_equal account_id, claims['sub']
      end
      assert_equal account_id, session[:account_id]
      assert_equal Rails.application.config.application_domains.first, session[:audience]
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

    test 'with untrusted referrer' do
      post accounts_path,
        params: {
          username: 'username',
          password: SecureRandom.hex(8)
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
      assert_json_result(true)
    end

    test 'with existing username' do
      account = FactoryGirl.create(:account)

      get available_accounts_path,
        params: {
          username: account.username
        }

      assert_response :unprocessable_entity
      assert_json_errors('username' => ErrorCodes::USERNAME_TAKEN)
    end

    test 'with locked username' do
      account = FactoryGirl.create(:account, :locked)

      get available_accounts_path,
        params: {
          username: account.username
        }

      assert_response :unprocessable_entity
      assert_json_errors('username' => ErrorCodes::USERNAME_TAKEN)
    end
  end

  testing '#lock' do
    test 'on active account' do
      account = FactoryGirl.create(:account)

      patch lock_account_path(account.id),
        headers: API_CREDENTIALS

      assert_response :ok
      assert account.reload.locked?
    end

    test 'on locked account' do
      account = FactoryGirl.create(:account, :locked)

      patch lock_account_path(account.id),
        headers: API_CREDENTIALS

      assert_response :ok
    end

    test 'on unknown account' do
      patch lock_account_path(0),
        headers: API_CREDENTIALS

      assert_response :not_found
      assert_json_errors(
        'account' => ErrorCodes::ACCOUNT_NOT_FOUND
      )
    end
  end

  testing '#unlock' do
    test 'on active account' do
      account = FactoryGirl.create(:account)

      patch lock_account_path(account.id),
        headers: API_CREDENTIALS

      assert_response :ok
    end

    test 'on locked account' do
      account = FactoryGirl.create(:account, :locked)

      patch unlock_account_path(account.id),
        headers: API_CREDENTIALS

      assert_response :ok
      refute account.reload.locked?
    end

    test 'on unknown account' do
      patch lock_account_path(0),
        headers: API_CREDENTIALS

      assert_response :not_found
      assert_json_errors(
        'account' => ErrorCodes::ACCOUNT_NOT_FOUND
      )
    end
  end

  testing '#destroy' do
    test 'with known account' do
      account = FactoryGirl.create(:account)

      delete account_path(account.id),
        headers: API_CREDENTIALS

      assert_response :ok
      assert account.reload.deleted_at?
    end

    test 'with unknown account' do
      delete account_path(rand(999)),
        headers: API_CREDENTIALS

      assert_response :not_found
      assert_json_errors(
        'account' => ErrorCodes::ACCOUNT_NOT_FOUND
      )
    end
  end
end
