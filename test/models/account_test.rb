require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test '#name validations' do
    assert_allows_value(Account.new, :name, 'a')
    refute_allows_values(Account.new, :name, [nil, ''])
  end

  test '#password validations' do
    assert_allows_value(Account.new, :password, BCrypt::Password.create('secret'))
    refute_allows_values(Account.new, :password, [nil, ''])
  end

  test '#confirm' do
    account = FactoryGirl.create(:account)
    refute account.confirmed?
    account.confirm
    assert account.confirmed?
    refute account.changes.any?
  end

  testing '.reclaim' do
    test 'with confirmed name' do
      account = FactoryGirl.create(:account, :confirmed)
      refute Account.reclaim(account.name)
      assert_nothing_raised do
        account.reload
      end
    end

    test 'with unconfirmed name' do
      account = FactoryGirl.create(:account)
      assert Account.reclaim(account.name)
      assert_raises ActiveRecord::RecordNotFound do
        account.reload
      end
    end
  end

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
end
