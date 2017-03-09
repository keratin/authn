ActivesTracker = Struct.new(:account_id)
class ActivesTracker
  # ISO 8601 date format
  DAY = '%Y-%m-%d'
  DAY_KEY = "actives:#{DAY}"

  # ISO 8601 week numberings don't perfectly match the Gregorian calendar. The first week of the
  # year doesn't begin until a Monday.
  WEEK = '%G-W%V'
  WEEK_KEY = "actives:#{WEEK}"

  # ISO 8601 date format
  MONTH = '%Y-%m'
  MONTH_KEY = "actives:#{MONTH}"

  def perform
    now = Time.now.in_time_zone(Rails.application.config.statistics_time_zone)
    day_key = now.strftime(DAY_KEY)
    week_key = now.strftime(WEEK_KEY)
    month_key = now.strftime(MONTH_KEY)

    REDIS.with do |conn|
      conn.pipelined do
        # increment daily
        conn.pfadd(day_key, account_id)
        conn.expire(day_key, Rails.application.config.daily_actives_retention * 86400)

        # increment weekly
        conn.pfadd(week_key, account_id)
        conn.expire(week_key, Rails.application.config.weekly_actives_retention * 7 * 86400)

        # increment monthly
        conn.pfadd(month_key, account_id)
      end
    end
  end
end
