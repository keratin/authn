require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  testing '#create' do
    test 'with valid credentials' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      post sessions_path,
        params: {
          name: account.name,
          password: 'valid'
        }

      assert_response(:created)
      assert_json_result('account_id' => account.id)
    end

    test 'with unknown account name' do
      post sessions_path,
        params: {
          name: 'unknown',
          password: 'valid'
        }

      assert_response(:unprocessable_entity)
      assert_json_errors('credentials' => 'invalid or unknown')
    end

    test 'with bad password' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      post sessions_path,
        params: {
          name: account.name,
          password: 'unknown'
        }

      assert_response(:unprocessable_entity)
      assert_json_errors('credentials' => 'invalid or unknown')
    end
  end
end
