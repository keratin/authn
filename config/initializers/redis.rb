size = [5, (ENV['THREAD_COUNT'] || 1) * 0.5].min

REDIS = ConnectionPool.new(size: size, timeout: 1) do
  Redis.new(url: ENV['REDIS_URL'] || "redis://localhost:6379/0")
end
