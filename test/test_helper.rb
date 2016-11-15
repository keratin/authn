ENV['RAILS_ENV'] ||= 'test'
ENV['REDIS_URL'] = "redis://localhost:6379/1"

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'sucker_punch/testing/inline'
require 'webmock/minitest'

# test speed
BCrypt::Engine.cost = BCrypt::Engine::MIN_COST

class ActionDispatch::IntegrationTest
  TRUSTED_REFERRER = {'REFERER' => "https://#{Rails.application.config.client_hosts.sample}"}
  UNTRUSTED_REFERRER = {'REFERER' => 'https://evil.com'}
  API_CREDENTIALS = {
    'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(
      Rails.application.config.api_username,
      Rails.application.config.api_password
    )
  }
end

class ActiveSupport::TestCase
  def self.testing(name, &block)
    raise "already testing #{@testing}" if @testing
    @testing = name
    yield
  ensure
    @testing = nil
  end

  def self.test(name, &block)
    super([@testing, name].join(' '), &block)
  end

  def teardown
    super
    REDIS.with{|conn| conn.flushall }
  end

  def with_session(account_id: nil, token: nil)
    account_id ||= rand(9999)
    ApplicationController.stub_any_instance(:session, {
      account_id: account_id,
      token: token || RefreshToken.create(account_id)}
    ) do
      yield
    end
  end

  private

  def assert_json_jwt(str)
    assert str.presence
    claims = JSON::JWT.decode(str, Rails.application.config.auth_public_key)
    yield claims
  end

  def assert_json_result(data = {})
    assert_equal JSONEnvelope.result(data), JSON.parse(response.body)
  end

  def assert_json_errors(errors)
    assert_equal JSONEnvelope.errors(errors), JSON.parse(response.body)
  end

  def assert_allows_value(model, attribute, value)
    model[attribute] = value
    model.validate
    refute model.errors[attribute].any?
  end

  def refute_allows_value(model, attribute, value, message: nil)
    model[attribute] = value
    model.validate
    assert model.errors[attribute].any?
    if message
      assert model.errors[attribute].include?(error)
    end
  end

  def refute_allows_values(model, attribute, values, message: nil)
    Array.wrap(values).each do |value|
      refute_allows_value(model, attribute, value, message: message)
    end
  end
end
