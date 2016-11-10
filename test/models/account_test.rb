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
end
