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

  before_save :encrypt_fields
  before_destroy :clear_incidents
  
  has_many :histories, :dependent => :destroy
  has_many :logs, :dependent => :destroy
  has_many :ports, :dependent => :destroy
  has_many :pages, :dependent => :destroy
  has_many :disks, :dependent => :destroy
  belongs_to :account
  has_many :monitor_servers, :dependent => :destroy

  validates_presence_of :name
  validates_presence_of :hostname, :if => :ssh_connection?
  validates_presence_of :ssh_port, :if => :ssh_connection?
  validates_presence_of :username, :if => :ssh_connection?
  validates_presence_of :url, :unless => :ssh_connection?

  after_initialize :do_after_initialize

  scope :active,
              :include => :account,
              :conditions => ['accounts.active = ? OR accounts.trial_end >= ?', true, Date.today]

  def ssh_connection?
    return @ssh_connection
  end

  def ssh(val)
    @ssh_connection = val
  end

  def port_limit_reached?
    if ports.count > 4
      return true
    end
  end

  def do_after_initialize
    if self.private_key == nil
      generate_keys(self.account_id)
    end
    if self.access_key == nil
      self.access_key = Digest::SHA1.hexdigest Time.now.to_s
    end
    true
  end

  def page_limit_reached?
    if pages.count > 4
      return true
    end
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
  <mysql>#{mysql}</mysql>
  <phpversion>#{phpversion}</phpversion>
  <apacheversion>#{apacheversion}</apacheversion>
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

  def retrieve_stats(decrypt_pass = false)

    begin

      xml = ''
      if ssh_connection? or self.url == nil
        xml = SysStats::Stats.live_stats_xml(hostname,
          username, password, ssh_port, id, private_key)
      else
        xml = retrieve_stats_agent
        response,body = xml_data = Net::HTTP.get_response(
          URI.parse(self.url + '?cmd=stats'))

        if response.kind_of? Net::HTTPSuccess
          xml = response.body
        end
      end

      process_stats_xml(xml)

    rescue Exception => e
      errors[:base] << 'Unable to connect ' + e.to_s
    end
  end

  def process_stats_xml(xml)

    doc = REXML::Document.new(xml)

    if doc.root.elements['processing'] == nil
      errors[:base] << 'Unable to parse results from agent'
    else
      #process data from agent
      self.usedswap = doc.root.elements['*/swapused'].to_s
      self.totalswap = doc.root.elements['*/swaptotal'].to_s

      self.usedmem = doc.root.elements['*/used'].to_s
      self.totalmem = doc.root.elements['*/total'].to_s

      self.cpuload = doc.root.elements['uptime'].to_s
      self.cpumhz = doc.root.elements['cpuinfo/cpumhz'].to_s
      self.cpu = doc.root.elements['cpuinfo/cpu'].to_s
      self.cpucount = doc.root.elements['cpuinfo/cpucount'].to_s

      self.apacheversion = doc.root.elements['apacheversion'].to_s
      self.platform = doc.root.elements['release'].to_s
      self.distro = doc.root.elements['uptime'].to_s
      self.phpversion = doc.root.elements['phpversion'].to_s
      self.kernelver = doc.root.elements['version'].to_s
      self.uptime = doc.root.elements['uptime'].to_s
    end
  end

  private

  def generate_keys(account_id)
    kc = Rails.cache.fetch("next_private_key#{account_id}") do
      kc = Keychain.find(rand(Keychain.count) + 1)
    end
    self.public_key = kc.public_key
    self.private_key = Base64.encode64(Encryptor.encrypt(
      :value => kc.private_key,
      :key => SysStats::JAKE_PURTON))
  end

  def decode_private_key
    return Encryptor.decrypt(:value => Base64.decode64(self.private_key),
      :key => SysStats::JAKE_PURTON)
  end

  def clear_private_key(id)
    Rails.cache.delete("next_private_key#{id}")
  end

  def encrypt_fields

    if password_changed? and !password.empty?

      p = Encryptor.encrypt(:value => self.password, 
        :key => SysStats::JAKE_PURTON)
      self.password = Base64.encode64(p)
    end
    clear_private_key(self.account_id)
    true
  end

  def clear_incidents
    incidents = account.incidents.where(:server_id => self.id)
    incidents.each { |incident| incident.destroy }
  end

  def validate_on_create
    errors.add(:account_id, 'limit reached') if account.limit_reached?
  end
end
