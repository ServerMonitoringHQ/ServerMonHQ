class MonitorServer < ActiveRecord::Base
  belongs_to :measure
  belongs_to :server

  scope :active,
              :include => {:server => :account},
              :conditions => ['accounts.active = ? OR accounts.trial_end >= ?', true, Date.today]
end
