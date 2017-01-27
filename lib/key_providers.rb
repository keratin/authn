require 'encryptor'

module KeyProviders
  # This provider is meant to be used when the host app is ready to take over responsibility for
  # key management and secure storage.
  class Static
    attr_reader :key

    def initialize(private_key)
      @key = private_key
    end

    def public_key
      key.public_key
    end

    def keys
      [@key]
    end
  end

  # This provider uses Redis to persist an auto-generated key and rotate it regularly. The key is
  # encrypted using SECRET_KEY_BASE, which is already the ultimate SPOF for AuthN security. It's
  # expected that very few people will be in position to improve on the security tradeoffs of this
  # provider.
  class Rotating
    PLACEHOLDER = 'generating'

    # the rotation interval should be slightly longer than access token expiry
    # this means that when a key goes inactive for some interval, we can know
    # that it is useless and discardable by the third interval.
    attr_reader :interval

    # if two clients need to regenerate a key at the same time, this is how long
    # one will have to attempt it while the other waits patiently.
    #
    # this should be greater than the peak time necessary to generate and encrypt a
    # 2048-bit key, plus send it back over the wire to redis.
    attr_reader :race_ms

    attr_reader :keys

    def initialize(
      interval: Rails.application.config.access_token_expiry,
      race_ms: 500,
      encryption_key: Rails.application.config.db_encryption_key
      )
      @interval = interval
      @race_ms = race_ms
      @encryptor = Encryptor.new(encryption_key)
      @keys = {}
    end

    def key
      bucket = Time.now.to_i / interval

      if !@keys[bucket]
        # find or create new key
        @keys[bucket] = fetch("rsa:#{bucket}") do
          OpenSSL::PKey::RSA.new(2048)
        end

        # trim old keys (keep 2)
        @keys.keys.sort[0...-2].each{|b| @keys.delete(b) }
      end

      @keys[bucket]
    end

    def public_key
      key.public_key
    end

    private def fetch(key)
      REDIS.with do |conn|
        loop do
          val = conn.get(key)
          if val && val != PLACEHOLDER
            break OpenSSL::PKey::RSA.new(@encryptor.decrypt(val))
          else
            if conn.set(key, PLACEHOLDER, px: race_ms, nx: true)
              val = yield.tap do |val|
                conn.set(key, @encryptor.encrypt(val.to_s), ex: interval * 2 + 10)
              end

              break val
            else
              sleep 0.05
            end
          end
        end
      end
    end
  end
end
