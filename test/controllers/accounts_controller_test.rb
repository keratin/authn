require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  testing '#create' do
    test 'with name and password' do
      post accounts_path,
        params: {
          name: 'username',
          password: 'secret'
        }

      assert_response :created
      assert_json_result('account_id' => 1)
    end

    test 'with missing fields' do
      post accounts_path,
        params: {}

      assert_response :unprocessable_entity
      assert_json_errors('name' => 'can\'t be blank')
    end

    test 'with insecure password' do
      post accounts_path,
        params: {
          name: 'username',
          password: 'insecure'
        }

      assert_response :unprocessable_entity
      assert_json_errors('password' => 'does not meet security requirements')
    end

    test 'with name of existing account' do
      account = FactoryGirl.create(:account)

      post accounts_path,
        params: {
          name: account.name,
          password: 'new password'
        }

      assert_response :unprocessable_entity
      assert_json_errors('name' => 'has already been taken')
    end
  end

  testing '#available' do
    test 'with unknown name' do
      get available_accounts_path,
        params: {
          name: 'unknown'
        }

      assert_response :success
      assert_json_result('available' => true)
    end

    test 'with existing name' do
      account = FactoryGirl.create(:account)

      get available_accounts_path,
        params: {
          name: account.name
        }

      assert_response :success
      assert_json_result('available' => false)
    end
  end
end
