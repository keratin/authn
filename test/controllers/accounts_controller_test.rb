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
end
