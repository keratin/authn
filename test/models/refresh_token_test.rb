require 'test_helper'

class RefreshTokenTest < ActiveSupport::TestCase
  test 'lifecycle' do
    account_id = rand(9999)

    hex = RefreshToken.create(account_id)
    assert_equal account_id.to_s, RefreshToken.find(hex)
    assert_equal [hex], RefreshToken.sessions(account_id)
    RefreshToken.revoke(hex)
    refute RefreshToken.find(hex)
    assert_equal [], RefreshToken.sessions(account_id)
  end
end
