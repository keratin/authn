ActivesTracker = Struct.new(:account_id) do
  # TODO: configurable time zone
  TZ = 'UTC'

  # ISO 8601 date format
  DAY = '%Y-%m-%d'

  # How many day-level HyperLogLog to keep
  DAY_RETENTION = 365 # one year

  # ISO 8601 week numberings don't perfectly match the Gregorian calendar. The first week of the
  # year doesn't begin until a Monday.
  WEEK = '%G-W%V'

  # How many week-level HyperLogLog to keep
  WEEK_RETENTION = 104 # two years

  # ISO 8601 date format
  MONTH = "%Y-%m"

  def perform
    now = Time.now.in_time_zone(TZ)
    day = now.strftime(DAY)
    week = now.strftime(WEEK)
    month = now.strftime(MONTH)

    REDIS.with do |conn|
      conn.pipelined do
        # increment daily
        conn.pfadd("actives:#{day}", account_id)
        conn.expire("actives:#{day}", DAY_RETENTION * 86400)

        # increment weekly
        conn.pfadd("actives:#{week}", account_id)
        conn.expire("actives:#{week}", WEEK_RETENTION * 7 * 86400)

        # increment monthly
        conn.pfadd("actives:#{month}", account_id)
      end
    end
  end
end
