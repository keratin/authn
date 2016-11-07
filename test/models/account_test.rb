require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test '#username validations' do
    assert_allows_value(Account.new, :username, 'a')
    refute_allows_values(Account.new, :username, [nil, ''])
  end

  test '#password validations' do
    assert_allows_value(Account.new, :password, BCrypt::Password.create('secret'))
    refute_allows_values(Account.new, :password, [nil, ''])
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
