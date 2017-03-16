require 'test_helper'

class PasswordExpirerTest < ActiveSupport::TestCase
  testing '#perform' do
    test 'success' do
      account = FactoryGirl.create(:account)

      assert PasswordExpirer.new(account.id).perform
      assert account.reload.require_new_password?
    end

    test 'with unknown account' do
      refute PasswordExpirer.new(0).perform
    end

    test 'with active sessions' do
      account = FactoryGirl.create(:account)
      hex = RefreshToken.create(account.id)

      assert RefreshToken.find(hex)
      PasswordExpirer.new(account.id).perform
      refute RefreshToken.find(hex)
    end
  end
end
