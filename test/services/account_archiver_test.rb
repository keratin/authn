require 'test_helper'

class AccountArchiverTest < ActiveSupport::TestCase
  testing '#perform' do
    test 'with active account' do
      account = FactoryGirl.create(:account)

      assert AccountArchiver.new(account.id).perform
      account.reload
      refute account.username
      refute account.password
      assert account.deleted_at?
    end

    test 'with locked account' do
      account = FactoryGirl.create(:account, :locked)
      assert AccountArchiver.new(account.id).perform
    end

    test 'with archived account' do
      account = FactoryGirl.create(:account, :archived)
      refute AccountArchiver.new(account.id).perform
    end

    test 'with unknown account' do
      refute AccountArchiver.new(0).perform
    end
  end
end
