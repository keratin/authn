size = ENV.fetch('RAILS_MAX_THREADS'){ 5 }.to_i

REDIS = ConnectionPool.new(size: size, timeout: 1) do
  Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')
end
