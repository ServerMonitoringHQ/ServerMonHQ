class Account < ActiveRecord::Base
  has_many :measures
  has_many :servers  
  has_many :users
  has_many :incidents

  validates_numericality_of :plan_id, :only_integer => true, :message => 'should be selected'

  def expired?
    !active? && trial_end <= Date.today
  end

  def server_limit_reached?
    
    count = servers.count

    if plan_id == 0 and count > 0
      return true
    end
    if plan_id == 1 and count > 4
      return true
    end
    if plan_id == 2 and count > 9
      return true
    end
    if plan_id == 3 and count > 19
      return true
    end
    
  end

  def limit_reached?
    return false
  end

  def plan

    plan_name = case plan_id
    when 0 then "Basic"
    when 1 then "Plus"
    when 2 then "Premium"
    when 3 then "Max"
    else "Unknown"
    end
  end
end
