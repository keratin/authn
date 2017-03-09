require 'test_helper'

class AccountImporterTest < ActiveSupport::TestCase
  def setup
    @args = {
      username: 'username@domain.tld',
      password: BCrypt::Password.create('hello world').to_s,
      locked: false
    }
    super
  end

  testing '#perform' do
    test 'success' do
      importer = AccountImporter.new(@args)
      account = importer.perform
      assert account.persisted?
    end

    test 'with missing username' do
      importer = AccountImporter.new(@args.merge(username: ''))
      refute importer.perform
      assert_equal [ErrorCodes::MISSING], importer.errors[:username]
    end

    test 'with duplicate username' do
      account = FactoryGirl.create(:account)
      importer = AccountImporter.new(@args.merge(username: account.username))
      refute importer.perform
      assert_equal [ErrorCodes::TAKEN], importer.errors[:username]
    end

    test 'with locked username' do
      account = FactoryGirl.create(:account, :locked)
      importer = AccountImporter.new(@args.merge(username: account.username))
      refute importer.perform
      assert_equal [ErrorCodes::TAKEN], importer.errors[:username]
    end

    test 'with plain name when emails are expected' do
      with_config(:email_usernames, true) do
        importer = AccountImporter.new(@args.merge(username: 'username'))
        assert importer.perform
      end
    end

    test 'with missing password' do
      importer = AccountImporter.new(@args.merge(password: ''))
      refute importer.perform
      assert_equal [ErrorCodes::MISSING], importer.errors[:password]
    end

    test 'with plaintext password' do
      importer = AccountImporter.new(@args.merge(password: 'plaintext'))
      account = importer.perform
      assert account.persisted?
      assert BCrypt::Password.new(account.password).is_password?('plaintext')
    end

    test 'with locked user' do
      importer = AccountImporter.new(@args.merge(locked: true))
      account = importer.perform
      assert account.persisted?
      assert account.locked?
    end

    test 'default value for locked arg' do
      importer = AccountImporter.new(@args.without(:locked))
      account = importer.perform
      refute account.locked?
    end
  end
end
