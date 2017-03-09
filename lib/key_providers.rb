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

    def initialize(
      interval: Rails.application.config.access_token_expiry,
      encryption_key: Rails.application.config.db_encryption_key,
      race_ms: 500,
      strength: 2048
    )
      @interval = interval
      @race_ms = race_ms
      @strength = strength
      @encryptor = Encryptor.new(encryption_key)
      @keys = {}
      @mutex = Mutex.new
    end

    def key
      bucket = Time.now.to_i / interval

      if !@keys[bucket]
        @mutex.synchronize do
          # another thread may have already accomplished this
          next if @keys[bucket]

          # find or create new key
          key_str = fetch("rsa:#{bucket}") do
            OpenSSL::PKey::RSA.new(@strength).to_s
          end

          # trim out old keys (keep 2)
          # this works because ruby hashes are ordered.
          @keys = @keys.to_a.last(1).to_h.merge(bucket => OpenSSL::PKey::RSA.new(key_str))
        end
      end

      @keys[bucket]
    end

    def keys
      @keys.values
    end

    def public_key
      key.public_key
    end

    private def fetch(key)
      REDIS.with do |conn|
        loop do
          val = conn.get(key)
          # exists
          if val && val != PLACEHOLDER
            break @encryptor.decrypt(val)
          # attempt lock and create it ourselves
          elsif conn.set(key, PLACEHOLDER, px: race_ms, nx: true)
            break yield.tap do |val|
              conn.set(key, @encryptor.encrypt(val.to_s), ex: interval * 2 + 10)
            end
          # wait
          else
            sleep 0.05
          end
        end
      end
    end
  end
end
