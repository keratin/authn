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
    account = Account.create!(name: 'account', password: BCrypt::Password.create('secret'))
    refute account.confirmed?
    account.confirm
    assert account.confirmed?
    refute account.changes.any?
  end
end
