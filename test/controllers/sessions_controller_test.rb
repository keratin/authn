require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  testing '#create' do
    test 'with valid credentials' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      post sessions_path,
        params: {
          name: account.name,
          password: 'valid'
        },
        headers: TRUSTED_REFERRER

      assert_response(:created)
      assert_json_result()
      assert_equal 1, session[:account_id]
    end

    test 'with unknown account name' do
      post sessions_path,
        params: {
          name: 'unknown',
          password: 'valid'
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('credentials' => 'invalid or unknown')
    end

    test 'with bad password' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      post sessions_path,
        params: {
          name: account.name,
          password: 'unknown'
        },
        headers: TRUSTED_REFERRER

      assert_response(:unprocessable_entity)
      assert_json_errors('credentials' => 'invalid or unknown')
    end

    test 'with untrusted referer' do
      account = FactoryGirl.create(:account, clear_password: 'valid')

      post sessions_path,
        params: {
          name: account.name,
          password: 'valid'
        },
        headers: UNTRUSTED_REFERRER

      assert_response(:forbidden)
      assert_json_errors('referer' => 'is not a trusted host')
    end
  end
end
