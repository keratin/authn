# Redis memory estimates:
#
# * ~470 bytes to store a token on a new account
# * ~246 bytes to store a second token on an existing account
#
# So an application with 1 million logged-in users and an average of 1.2 sessions/account would use
# around 500mb memory.
#
# NOTE: the cryptic keys are to save memory
module RefreshToken
  # returns: account_id or nil
  def self.find(hex)
    bin = [hex].pack('H*')

    REDIS.with do |conn|
      conn.get("s:t.#{bin}")
    end
  end

  def self.touch(token:, account_id:)
    return unless account_id.present?
    bin = [token].pack('H*')
    REDIS.with do |conn|
      conn.pipelined do
        conn.expire("s:t.#{bin}", Rails.application.config.refresh_token_expiry)
        conn.expire("s:a.#{account_id}", Rails.application.config.refresh_token_expiry)
      end
    end
  end

  # returns: array of hex tokens
  def self.sessions(account_id)
    REDIS.with do |conn|
      conn.smembers("s:a.#{account_id}")
        .map{|bin| bin.unpack('H*').first }
    end
  end

  # returns: hex token
  def self.create(account_id)
    hex = generate_token()
    bin = [hex].pack('H*')

    REDIS.with do |conn|
      conn.pipelined do
        # persist the token
        conn.set("s:t.#{bin}", account_id, ex: Rails.application.config.refresh_token_expiry)

        # maintain a list of tokens per account id
        conn.sadd("s:a.#{account_id}", bin)
        conn.expire("s:a.#{account_id}", Rails.application.config.refresh_token_expiry)
      end
    end
    hex
  end

  def self.revoke(hex)
    bin = [hex].pack('H*')
    REDIS.with do |conn|
      account_id = conn.get("s:t.#{bin}")
      conn.pipelined do
        conn.del("s:t.#{bin}")
        conn.srem("s:a.#{account_id}", bin)
      end
    end
  end

  # 128 bits of randomness is more than a UUID v4
  def self.generate_token
    SecureRandom.hex(16)
  end
end
