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
      assert_equal [ErrorCodes::MISSING], creator.errors[:username]
    end

    test 'with duplicate username' do
      account = FactoryGirl.create(:account)
      creator = AccountCreator.new(account.username, SecureRandom.hex(8))
      refute creator.perform
      assert_equal [ErrorCodes::TAKEN], creator.errors[:username]
    end

    test 'with locked username' do
      account = FactoryGirl.create(:account, :locked)
      creator = AccountCreator.new(account.username, SecureRandom.hex(8))
      refute creator.perform
      assert_equal [ErrorCodes::TAKEN], creator.errors[:username]
    end

    test 'with missing password' do
      creator = AccountCreator.new('username', nil)
      refute creator.perform
      assert_equal [ErrorCodes::MISSING], creator.errors[:password]
    end

    test 'with a weak password' do
      creator = AccountCreator.new('username', 'secret')
      refute creator.perform
      assert_equal [ErrorCodes::INSECURE], creator.errors[:password]
    end

    test 'with short username' do
      creator = AccountCreator.new('a', SecureRandom.hex(8))
      refute creator.perform
      assert_equal [ErrorCodes::FORMAT_INVALID], creator.errors[:username]
    end

    test 'with plain name when emails are expected' do
      with_config(:email_usernames, true) do
        creator = AccountCreator.new('username', SecureRandom.hex(8))
        refute creator.perform
        assert_equal [ErrorCodes::FORMAT_INVALID], creator.errors[:username]
      end
    end
  end
end
