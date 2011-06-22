class MonitorUser < ActiveRecord::Base
  belongs_to :measure 
  belongs_to :user    

  scope :active,
              :include => {:user => :account},
              :conditions => ['accounts.active = ? OR accounts.trial_end >= ?', true, Date.today]
end
