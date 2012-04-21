class Server < ActiveRecord::Base
  
  require 'net/ssh'
  require 'net/http'
  require 'open-uri'
  require 'timeout'
  require 'encryptor'
  require 'base64'
  require 'digest/sha1'
  require 'rexml/document'
  require 'keychain'
  require 'systats'

  before_destroy :clear_incidents
  
  has_many :histories, :dependent => :destroy
  has_many :logs, :dependent => :destroy
  has_many :ports, :dependent => :destroy
  has_many :pages, :dependent => :destroy
  has_many :disks, :dependent => :destroy
  belongs_to :account
  has_many :monitor_servers, :dependent => :destroy

  validates_presence_of :name

  after_initialize :do_after_initialize
  
  scope :by_access_key, lambda { |key|
    { :conditions => [ "access_key LIKE ?", key ] }
  }
  
  scope :active,
              :include => :account,
              :conditions => ['accounts.active = ? OR accounts.trial_end >= ?', true, Date.today]

  def to_hash
    @server_hash ||= begin
      {
        :id          => id,
        :hostname    => hostname,
        :username    => username,
        :password    => password,
        :port        => ssh_port, 
        :url         => url,
        :private_key => keychain.private_key
      }
    end
  end

  def ssh_connection?
    return @ssh_connection
  end

  def ssh(val)
    @ssh_connection = val
  end

  def do_after_initialize

    if self.access_key == nil
      self.access_key = SecureRandom.urlsafe_base64(8)
    end
    true
  end

  def port_limit_reached?
    if ports.count > 4
      return true
    end
  end

  def page_limit_reached?
    if pages.count > 4
      return true
    end
  end

  def pages_up?
    pgs = pages.find_by_status(0);
    if pgs == nil
      return true
    end
    return false
  end

  def ports_up?
    pgs = ports.find_by_status(0);
    if pgs == nil
      return true
    end
    return false
  end

  def top_xml

xml = <<EOF
<top>
  <top>#{top}</top>
  <load1>#{cpuload}</load1>
  <load2>#{load2}</load2>
  <load3>#{load3}</load3>
</top>
EOF

    return xml
  end

  def memory_xml

xml = <<EOF
<memory>
  <total>#{totalmem}</total>
  <swaptotal>#{totalswap}</swaptotal>
  <used>#{usedmem}</used>
  <swapused>#{usedswap}</swapused>
</memory>
EOF

    return xml
  end

  def stats_xml

    drive_data = ''
    disks.each do |disk|
drive_data += <<EOF
    <drive>
      <path>#{disk.path}</path>
      <totalspace>#{disk.totalspace}</totalspace>
      <usedspace>#{disk.usedspace}</usedspace>
      <percent>#{disk.percent}</percent>
    </drive>
EOF
    end

xml = <<EOF
<status>
  <id>#{id}</id>
  <cpuinfo>
    <cpu>#{cpu}</cpu>
    <cpucount>#{cpucount}</cpucount>
    <cpumhz>#{cpumhz}</cpumhz>
  </cpuinfo>
  <memory>
    <total>#{totalmem}</total>
    <swaptotal>#{totalswap}</swaptotal>
    <used>#{usedmem}</used>
    <swapused>#{usedswap}</swapused>
  </memory>
  <load>
    <load1>#{cpuload}</load1>
    <load2>#{load2}</load2>
    <load3>#{load3}</load3>
  </load>
  <uptime>#{uptime}</uptime>
  <bandwidth>
    <tx>#{last_tx}</tx> 
    <rx>#{last_rx}</rx>
  </bandwidth>
  <release>#{distro}</release>
  <version>#{kernelver}</version>
  <drives>#{drive_data}</drives>
</status>
EOF

  return xml

  end
 
  
  def load_percentage
    if cpuload != nil
      return (cpuload / 1.0) * 100
    end
    return 0
  end
  
  def mem_percentage
    if usedmem != nil
      return "%.1f" % ((usedmem / totalmem) * 100)
    end
    return 0
  end
  
  def swap_percentage
    if usedswap != nil and totalswap != 0
      return "%.1f" % ((usedswap / totalswap) * 100)
    end
    return 0
  end

  private

  def clear_incidents
    incidents = account.incidents.where(:server_id => self.id)
    incidents.each { |incident| incident.destroy }
  end

  def validate_on_create
    errors.add(:account_id, 'limit reached') if account.limit_reached?
  end
end
