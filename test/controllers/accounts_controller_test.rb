require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test '#create with name and password' do
    post accounts_path,
      params: {
        name: 'username',
        password: 'secret'
      }

    assert_response :created
    assert_json_result('account_id' => 1)
  end

  test '#create with missing fields' do
    post accounts_path,
      params: {}

    assert_response :unprocessable_entity
    assert_json_errors('name' => 'can\'t be blank')
  end

  test '#create with insecure password' do
    post accounts_path,
      params: {
        name: 'username',
        password: 'insecure'
      }

    assert_response :unprocessable_entity
    assert_json_errors('password' => 'does not meet security requirements')
  end

  test '#create with name of confirmed account' do
    account = FactoryGirl.create(:account, :confirmed)

    post accounts_path,
      params: {
        name: account.name,
        password: 'new password'
      }

    assert_response :unprocessable_entity
    assert_json_errors('name' => 'has already been taken')
  end

  test '#create with name of unconfirmed account' do
    account = FactoryGirl.create(:account)

    post accounts_path,
      params: {
        name: account.name,
        password: 'new password'
      }

    assert_response :created
    assert_json_result('account_id' => account.id + 1)
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

    test 'with confirmed name' do
      account = FactoryGirl.create(:account, :confirmed)

      get available_accounts_path,
        params: {
          name: account.name
        }

      assert_response :success
      assert_json_result('available' => false)
    end

    test 'with unconfirmed name' do
      account = FactoryGirl.create(:account)

      get available_accounts_path,
        params: {
          name: account.name
        }

      assert_response :success
      assert_json_result('available' => true)
    end
  end

  test '#confirm with unconfirmed account' do
    account = FactoryGirl.create(:account)
    patch confirm_account_path(id: account.id)
    assert_response :success

    account.reload.confirmed?
  end

  test '#confirm with confirmed account' do
    account = FactoryGirl.create(:account, :confirmed)
    patch confirm_account_path(id: account.id)
    assert_response :success
  end

  test '#confirm with unknown account' do
    patch confirm_account_path(id: rand(999))
    assert_response :not_found
  end
end
