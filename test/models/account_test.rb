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
end
