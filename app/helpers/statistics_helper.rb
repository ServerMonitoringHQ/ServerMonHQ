module StatisticsHelper

  def graph_hours_of_day

    Time.zone = 'UTC'

    t = Time.zone.now
    s = ''

    (1..6).each do |index|
      s = t.strftime('||||%a %H:%M') + s
      t = t - 4.hour
    end

    return s
  end

  def graph_months_of_year
    Time.zone = 'UTC'

    t = Time.now
    s = '|'

    (1..12).each do |index|
      s = '|' + t.strftime('%b %y') + s
      t = t - 1.month
    end
    
    return s

  end

  def graph_days_of_week
    Time.zone = 'UTC'

    t = Time.now
    s = '|'

    (1..7).each do |index|
      s = '|' + t.strftime('%a %d') + s
      t = t - 1.day
    end
    
    return s

  end

end
