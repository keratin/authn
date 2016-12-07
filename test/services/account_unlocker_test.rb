require 'test_helper'

class AccountUnlockerTest < ActiveSupport::TestCase
  testing '#perform' do
    test 'with active account' do
      account = FactoryGirl.create(:account)

      refute AccountUnlocker.new(account.id).perform
    end

    test 'with locked account' do
      account = FactoryGirl.create(:account, :locked)
      assert AccountUnlocker.new(account.id).perform
      refute account.reload.locked?
    end

    test 'with archived account' do
      account = FactoryGirl.create(:account, :archived)
      refute AccountUnlocker.new(account.id).perform
    end

    test 'with unknown account' do
      refute AccountUnlocker.new(0).perform
    end
  end
end
