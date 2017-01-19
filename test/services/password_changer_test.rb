require 'test_helper'

class PasswordChangerTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze
    super
  end

  def teardown
    super
    Timecop.return
  end

  testing '#perform' do
    test 'with account_id and password' do
      account = FactoryGirl.create(:account)
      updater = PasswordChanger.new(account.id, SecureRandom.hex(8))

      assert updater.perform
      assert account.reload.authenticate(updater.password)
    end

    test 'with a missing password' do
      account = FactoryGirl.create(:account)
      updater = PasswordChanger.new(account.id, '')

      refute updater.perform
      assert_equal [ErrorCodes::MISSING], updater.errors[:password]
    end

    test 'with a weak password' do
      account = FactoryGirl.create(:account)
      updater = PasswordChanger.new(account.id, 'password')

      refute updater.perform
      assert_equal [ErrorCodes::INSECURE], updater.errors[:password]
    end

    test 'with missing account_id' do
      updater = PasswordChanger.new(nil, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::NOT_FOUND], updater.errors[:account]
    end

    test 'with archived account' do
      account = FactoryGirl.create(:account, :archived)
      updater = PasswordChanger.new(account.id, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::NOT_FOUND], updater.errors[:account]
    end

    test 'with locked account' do
      account = FactoryGirl.create(:account, :locked)
      updater = PasswordChanger.new(account.id, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::LOCKED], updater.errors[:account]
    end
  end
end
