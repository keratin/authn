ENV['RAILS_ENV'] ||= 'test'

require 'coveralls'
Coveralls.wear!

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'sucker_punch/testing/inline'
require 'webmock/minitest'

# test speed
BCrypt::Engine.cost = BCrypt::Engine::MIN_COST

class ActionDispatch::IntegrationTest
  TRUSTED_REFERRER = {'REFERER' => "https://#{Rails.application.config.application_domains.sample}"}
  UNTRUSTED_REFERRER = {'REFERER' => 'https://evil.com'}
  API_CREDENTIALS = {
    'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(
      Rails.application.config.api_username,
      Rails.application.config.api_password
    )
  }

  def options(path, **args)
    @html_document = nil
    integration_session.__send__(:process, :options, path, **args).tap do
      copy_session_variables!
    end
  end

  def cors_get(path, **args)
    assert_cors(:get, path)
    get(path, **args)
  end

  def cors_post(path, **args)
    assert_cors(:post, path)
    post(path, **args)
  end

  def cors_delete(path, **args)
    assert_cors(:delete, path)
    delete(path, **args)
  end

  def assert_cors(verb, path)
    options path,
      headers: {
        'Origin' => TRUSTED_REFERRER['REFERER'],
        'Access-Control-Request-Method' => verb.to_s.upcase,
        'Access-Control-Request-Headers' => 'Content-Type'
      }
    assert_response(:ok)
    assert_equal TRUSTED_REFERRER['REFERER'], response.headers['Access-Control-Allow-Origin']
    assert verb.to_s.upcase.in?(response.headers['Access-Control-Allow-Methods'].split(',').map(&:strip))
  end

  def authn_session
    JSON::JWT.decode(cookies[AuthNSession::NAME], Rails.application.config.session_key)
  end

  def assert_json_jwt(str)
    assert str.presence
    claims = JSON::JWT.decode(str, Rails.application.config.key_provider.public_key)
    yield claims
  end

  def assert_json_result(data = {})
    assert_equal JSONEnvelope.result(data), JSON.parse(response.body)
  end

  def assert_json_errors(errors)
    assert_equal JSONEnvelope.errors(errors), JSON.parse(response.body)
  end

  def with_session(account_id: nil, token: nil)
    account_id ||= rand(9999)
    ApplicationController.stub_any_instance(
      :authn_session,
      sub: token || RefreshToken.create(account_id)
    ) do
      yield
    end
  end
end

class ActiveSupport::TestCase
  def self.testing(name)
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
    REDIS.with(&:flushall)
  end

  def with_config(key, value)
    previous_value = Rails.application.config.send(key)
    begin
      Rails.application.config.send("#{key}=", value)
      yield
    ensure
      Rails.application.config.send("#{key}=", previous_value)
    end
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
    assert model.errors[attribute].include?(error) if message
  end

  def refute_allows_values(model, attribute, values, message: nil)
    Array.wrap(values).each do |value|
      refute_allows_value(model, attribute, value, message: message)
    end
  end
end
