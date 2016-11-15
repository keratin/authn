require 'test_helper'

class AccountCreatorTest < ActiveSupport::TestCase
  testing '#perform' do
    test 'with unique username and secure password' do
      creator = AccountCreator.new('username', SecureRandom.hex(8))
      account = creator.perform
      assert account.persisted?
    end

    test 'with missing username' do
      creator = AccountCreator.new(nil, SecureRandom.hex(8))
      refute creator.perform
      assert_equal [ErrorCodes::USERNAME_MISSING], creator.errors[:username]
    end

    test 'with duplicate username' do
      account = FactoryGirl.create(:account)
      creator = AccountCreator.new(account.username, SecureRandom.hex(8))
      refute creator.perform
      assert_equal [ErrorCodes::USERNAME_TAKEN], creator.errors[:username]
    end

    test 'with missing password' do
      creator = AccountCreator.new('username', nil)
      refute creator.perform
      assert_equal [ErrorCodes::PASSWORD_MISSING], creator.errors[:password]
    end

    test 'with a weak password' do
      creator = AccountCreator.new('username', 'secret')
      refute creator.perform
      assert_equal [ErrorCodes::PASSWORD_INSECURE], creator.errors[:password]
    end
  end
end
