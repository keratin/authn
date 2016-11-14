require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  testing '#edit' do
    test 'with known username' do
      account = FactoryGirl.create(:account)

      get edit_password_path,
        params: {
          username: account.username
        }

      assert_response(:success)
      # TODO: assert background job. webmock?
    end

    test 'with unknown username' do
      get edit_password_path,
        params: {
          username: 'unknown'
        }

      assert_response(:success)
      # TODO: expect no background job. webmock?
    end
  end
end
