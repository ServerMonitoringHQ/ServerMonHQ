class Measure < ActiveRecord::Base  

  belongs_to :account
  validates_presence_of :name

  has_many :monitor_users, :dependent => :destroy
  has_many :monitor_servers, :dependent => :destroy
  has_many :users, :through => :monitor_users
  has_many :servers, :through => :monitor_servers

  before_destroy :clear_incidents

  def set_defaults
    self.mem_perc ||= 80
    self.load_perc ||= 80
    self.swap_perc ||= 80
    self.disk_perc ||= 80 
    self.notify_mem ||= true
    self.notify_load ||= true
    self.notify_swap ||= true
    self.notify_heartbeat ||= true
    self.notify_pages ||= true
    self.notify_ports ||= true
    self.notify_disk ||= true
  end

  protected

  def clear_incidents
    incidents = account.incidents.where(:measure_id => self.id)
    incidents.each { |incident| incident.destroy }
  end

end

