require 'test_helper'

class KeyProvidersTest < ActiveSupport::TestCase
  def setup
    @interval = 10
    Timecop.freeze
    super
  end

  def teardown
    super
    Timecop.return
  end

  testing 'Static' do
    test 'wraps a key' do
      key = OpenSSL::PKey::RSA.new(512)
      provider = KeyProviders::Static.new(key)
      assert_equal key.to_s, provider.key.to_s
    end
  end

  testing 'Rotating' do
    test 'missing key' do
      provider = KeyProviders::Rotating.new(interval: @interval, strength: 512)
      key = provider.key
      assert key
      assert key.is_a?(OpenSSL::PKey::RSA)
    end

    test 'rotation' do
      provider = KeyProviders::Rotating.new(interval: @interval, strength: 512)

      key1 = provider.key
      assert_equal key1, provider.key, "can fetch the same key again"

      Timecop.travel(@interval)
      key2 = provider.key
      refute_equal key1, key2, "key rotates"

      Timecop.travel(@interval)
      key3 = provider.key
      assert_equal [key2, key3], provider.keys.values, "keep one old key"
    end

    test 'existing key' do
      other_provider = KeyProviders::Rotating.new(interval: @interval, strength: 512)
      key = other_provider.key

      provider = KeyProviders::Rotating.new(interval: @interval, strength: 512)
      assert_equal key.to_s, provider.key.to_s
    end

    test 'injected key' do
      encryptor = Encryptor.new('evil' * 8)
      weak_key = OpenSSL::PKey::RSA.new(512)
      REDIS.with do |conn|
        conn.set("rsa:#{Time.now.to_i / @interval}", encryptor.encrypt(weak_key.to_s))
      end

      provider = KeyProviders::Rotating.new(interval: @interval, strength: 512)
      assert_raises Encryptor::InvalidMessage do
        provider.key
      end
    end

    test 'thread races' do
      provider = KeyProviders::Rotating.new(interval: @interval, strength: 512)
      keys = []
      2.times.map do
        Thread.new{
          keys << provider.key
        }
      end.each(&:join)

      assert_equal 1, keys.uniq.count
      assert_equal 1, provider.keys.count
    end
  end

end
