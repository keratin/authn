ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

# test speed
BCrypt::Engine.cost = BCrypt::Engine::MIN_COST

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

  private

  def assert_json_result(data)
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
