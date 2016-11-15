require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  testing '#authenticate' do
    test 'with matching password' do
      account = Account.new(password: BCrypt::Password.create('valid'))
      assert account.authenticate('valid')
    end

    test 'with mismatching password' do
      account = Account.new(password: BCrypt::Password.create('valid'))
      refute account.authenticate('unknown')
    end
  end

  testing '#set_password_changed_at' do
    test 'when creating account' do
      account = FactoryGirl.create(:account, password_changed_at: nil)
      assert account.password_changed_at
    end

    test 'when updating password' do
      account = FactoryGirl.create(:account)
      account.update_column(:password_changed_at, 1.month.ago)

      account.update(password: BCrypt::Password.create('new'))
      assert account.password_changed_at > 1.month.ago
    end

    test 'when updating username' do
      account = FactoryGirl.create(:account)
      account.update_column(:password_changed_at, 1.month.ago)

      account.update(username: 'new')
      refute account.password_changed_at > 1.month.ago
    end
  end
end
