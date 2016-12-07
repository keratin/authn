require 'test_helper'

class PasswordUpdaterTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze
    super
  end

  def teardown
    super
    Timecop.return
  end

  testing '#perform' do
    test 'with valid token and password' do
      account = FactoryGirl.create(:account)
      token = jwt(account)
      updater = PasswordUpdater.new(token, SecureRandom.hex(8))

      assert updater.perform
      assert account.reload.authenticate(updater.password)
    end

    test 'with missing token' do
      updater = PasswordUpdater.new('', SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::TOKEN_INVALID_OR_EXPIRED], updater.errors[:token]
    end

    test 'with tampered token' do
      account = FactoryGirl.create(:account)
      token = jwt(account, iss: 'https://elsewhere.tech')
      updater = PasswordUpdater.new(token, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::TOKEN_INVALID_OR_EXPIRED], updater.errors[:token]
    end

    test 'with valid token from malicious issuer' do
      account = FactoryGirl.create(:account)
      token = jwt(account, iss: 'https://evil.tech')
      updater = PasswordUpdater.new(token, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::TOKEN_INVALID_OR_EXPIRED], updater.errors[:token]
    end

    test 'with repurposed token' do
      account = FactoryGirl.create(:account)
      token = jwt(account, scope: 'OTHER')
      updater = PasswordUpdater.new(token, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::TOKEN_INVALID_OR_EXPIRED], updater.errors[:token]
    end

    test 'with expired token' do
      account = FactoryGirl.create(:account)
      token = jwt(account, exp: 1.hour.ago)
      updater = PasswordUpdater.new(token, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::TOKEN_INVALID_OR_EXPIRED], updater.errors[:token]
    end

    test 'when password has been changed since issuing token' do
      account = FactoryGirl.create(:account)
      token = jwt(account)
      updater = PasswordUpdater.new(token, SecureRandom.hex(8))

      Timecop.travel(1)
      assert updater.perform

      refute updater.perform
      assert_equal [ErrorCodes::TOKEN_INVALID_OR_EXPIRED], updater.errors[:token]
    end

    test 'with a missing password' do
      account = FactoryGirl.create(:account)
      token = jwt(account)
      updater = PasswordUpdater.new(token, '')

      refute updater.perform
      assert_equal [ErrorCodes::PASSWORD_MISSING], updater.errors[:password]
    end

    test 'with a weak password' do
      account = FactoryGirl.create(:account)
      token = jwt(account)
      updater = PasswordUpdater.new(token, 'password')

      refute updater.perform
      assert_equal [ErrorCodes::PASSWORD_INSECURE], updater.errors[:password]
    end

    test 'with archived account' do
      account = FactoryGirl.create(:account, :archived)
      token = jwt(account)
      updater = PasswordUpdater.new(token, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::ACCOUNT_NOT_FOUND], updater.errors[:account]
    end

    test 'with locked account' do
      account = FactoryGirl.create(:account, :locked)
      token = jwt(account)
      updater = PasswordUpdater.new(token, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::ACCOUNT_LOCKED], updater.errors[:account]
    end
  end

  private def jwt(account, claim_overrides = {})
    JSON::JWT.new(claims(account, claim_overrides))
      .sign(Rails.application.config.auth_private_key, Rails.application.config.auth_signing_alg).to_s
  end

  private def claims(account, overrides = {})
    {
      iss: Rails.application.config.authn_url,
      sub: account.id,
      aud: Rails.application.config.authn_url,
      exp: Time.now.utc.to_i + Rails.application.config.password_reset_expiry,
      iat: Time.now.utc.to_i,
      scope: PasswordUpdater::SCOPE,
      lock: account.password_changed_at.to_i
    }.merge(overrides)
  end
end
