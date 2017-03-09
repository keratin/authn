class ActivesReporter
  def initialize
    @trailing_days = Rails.application.config.daily_actives_retention
    @trailing_weeks = Rails.application.config.weekly_actives_retention
    @trailing_months = 5 * 12
  end

  def perform
    REDIS.with do |conn|
      {
        daily: trim(days.map{|d| d.strftime(ActivesTracker::DAY) }.zip(dailies(conn))).to_h,
        weekly: trim(weeks.map{|w| w.strftime(ActivesTracker::WEEK) }.zip(weeklies(conn))).to_h,
        monthly: trim(months.map{|m| m.strftime(ActivesTracker::MONTH) }.zip(monthlies(conn))).to_h
      }
    end
  end

  def days
    @days ||= Array.new(@trailing_days){|i| Date.today - i }.reverse
  end

  def weeks
    @weeks ||= Array.new(@trailing_weeks){|i| Date.today - 7 * i }.reverse
  end

  def months
    @months ||= Array.new(@trailing_months){|i| Date.today << i }.reverse
  end

  private def trim(pairs)
    pairs.drop_while{|_, v| v.zero? }
  end

  private def dailies(conn)
    actives(conn, days, ActivesTracker::DAY_KEY)
  end

  private def weeklies(conn)
    actives(conn, weeks, ActivesTracker::WEEK_KEY)
  end

  private def monthlies(conn)
    actives(conn, months, ActivesTracker::MONTH_KEY)
  end

  private def actives(conn, set, formatter)
    conn.pipelined do
      set.map{|i| conn.pfcount(i.strftime(formatter)) }
    end
  end
end
