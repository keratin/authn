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

      authn_session.tap do |session|
        assert_equal account_id, RefreshToken.find(session[:sub])
        assert_equal Rails.application.config.authn_url, session[:aud]
        assert_equal Rails.application.config.application_domains.first, session[:azp]
      end
    end

    test 'with missing fields' do
      post accounts_path,
        params: {},
        headers: TRUSTED_REFERRER

      assert_response :unprocessable_entity
      assert_json_errors(
        'username' => ErrorCodes::MISSING,
        'password' => ErrorCodes::MISSING
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
      assert_json_errors('username' => ErrorCodes::TAKEN)
    end

    test 'with locked username' do
      account = FactoryGirl.create(:account, :locked)

      get available_accounts_path,
        params: {
          username: account.username
        }

      assert_response :unprocessable_entity
      assert_json_errors('username' => ErrorCodes::TAKEN)
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
        'account' => ErrorCodes::NOT_FOUND
      )
    end

    test 'without credentials' do
      account = FactoryGirl.create(:account)

      patch lock_account_path(account.id)

      assert_response :unauthorized
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
        'account' => ErrorCodes::NOT_FOUND
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
        'account' => ErrorCodes::NOT_FOUND
      )
    end
  end
end
