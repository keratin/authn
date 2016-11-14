module RefreshToken
  # returns: account_id or nil
  def self.find(hex)
    bin = [hex].pack('H*')

    REDIS.with do |conn|
      conn.get("s:t.#{bin}")
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
      # persist the token
      conn.set("s:t.#{bin}", account_id)

      # maintain a list of tokens per account id
      conn.sadd("s:a.#{account_id}", bin)
    end

    hex
  end

  def self.revoke(hex)
    bin = [hex].pack('H*')
    REDIS.with do |conn|
      account_id = conn.get("s:t.#{bin}")
      conn.del("s:t.#{bin}")
      conn.srem("s:a.#{account_id}", bin)
    end
  end

  # 128 bits of randomness is more than a UUID v4
  def self.generate_token
    SecureRandom.hex(16)
  end
end
