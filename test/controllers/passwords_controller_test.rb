require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  testing '#edit' do
    test 'with known username' do
      password_reset_url = Rails.application.config.application_endpoints[:password_reset_uri].to_s
      stub_request(:post, password_reset_url)

      account = FactoryGirl.create(:account)

      get edit_password_path,
        params: {
          username: account.username
        }

      assert_response(:success)
      assert_requested(:post, password_reset_url) do |req|
        assert req.body.include?("account_id=#{account.id}")
        assert req.body.include?("token=")
      end
    end

    test 'with unknown username' do
      get edit_password_path,
        params: {
          username: 'unknown'
        }

      assert_response(:success)
    end
  end
end
