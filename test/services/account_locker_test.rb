require 'test_helper'

class AccountLockerTest < ActiveSupport::TestCase
  testing '#perform' do
    test 'with active account' do
      account = FactoryGirl.create(:account)

      assert AccountLocker.new(account.id).perform
      assert account.reload.locked?
    end

    test 'with locked account' do
      account = FactoryGirl.create(:account, :locked)
      refute AccountLocker.new(account.id).perform
    end

    test 'with archived account' do
      account = FactoryGirl.create(:account, :archived)
      refute AccountLocker.new(account.id).perform
    end

    test 'with unknown account' do
      refute AccountLocker.new(0).perform
    end
  end
end
