require 'test_helper'

class PasswordResetterTest < ActiveSupport::TestCase
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
      updater = PasswordResetter.new(token, SecureRandom.hex(8))

      assert updater.perform
      assert account.reload.authenticate(updater.password)
    end

    test 'with missing token' do
      updater = PasswordResetter.new('', SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::INVALID_OR_EXPIRED], updater.errors[:token]
      assert_equal [], updater.errors[:account]
    end

    test 'with invalid token' do
      account = FactoryGirl.create(:account)
      token = jwt(account, iss: 'https://elsewhere.tech')
      updater = PasswordResetter.new(token, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::INVALID_OR_EXPIRED], updater.errors[:token]
    end

    test 'when password has been changed since issuing token' do
      account = FactoryGirl.create(:account)
      token = jwt(account)
      updater = PasswordResetter.new(token, SecureRandom.hex(8))

      Timecop.travel(1)
      assert updater.perform

      refute updater.perform
      assert_equal [ErrorCodes::INVALID_OR_EXPIRED], updater.errors[:token]
    end

    test 'with a missing password' do
      account = FactoryGirl.create(:account)
      token = jwt(account)
      updater = PasswordResetter.new(token, '')

      refute updater.perform
      assert_equal [ErrorCodes::MISSING], updater.errors[:password]
    end

    test 'with a weak password' do
      account = FactoryGirl.create(:account)
      token = jwt(account)
      updater = PasswordResetter.new(token, 'password')

      refute updater.perform
      assert_equal [ErrorCodes::INSECURE], updater.errors[:password]
    end

    test 'with archived account' do
      account = FactoryGirl.create(:account, :archived)
      token = jwt(account)
      updater = PasswordResetter.new(token, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::NOT_FOUND], updater.errors[:account]
    end

    test 'with locked account' do
      account = FactoryGirl.create(:account, :locked)
      token = jwt(account)
      updater = PasswordResetter.new(token, SecureRandom.hex(8))

      refute updater.perform
      assert_equal [ErrorCodes::LOCKED], updater.errors[:account]
    end
  end

  private def jwt(account, claim_overrides = {})
    PasswordResetJWT.new({
      iss: Rails.application.config.authn_url,
      sub: account.id,
      aud: Rails.application.config.authn_url,
      exp: Time.now.utc.to_i + Rails.application.config.password_reset_expiry,
      iat: Time.now.utc.to_i,
      scope: PasswordResetter::SCOPE,
      lock: account.password_changed_at.to_i
    }.merge(claim_overrides))
      .to_s
  end
end
