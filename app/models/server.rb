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

  CMD_BANDWIDTH = "cat /proc/net/dev | grep '^.*[^lo]:' | awk '{print $1, $9 }'"
  CMD_TOP = "top -b -n 1 | head -n 27 | tail -n 22"
  CMD_LOG = "tail -n 20 [path] 2>&1"
  CMD_NETSTAT = "netstat -ln"
  CMD_LOAD_AVG = "cat /proc/loadavg"
  JAKE_KEY = 'Jake Purton, 18/8/2005'

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

  def Server.memory_info(res)
    
    total_mem = 0
    free_mem = 0
    total_swap = 0
    free_swap = 0
    buffer_mem = 0
    cache_mem = 0
    shared_mem = 0

    res.each { |memitem|
      val = memitem.split(':')
      s = val[1]
      s = s['kB']= '' unless s['kB'] == nil
      s.strip!

      total_mem = val[1].strip.to_i if val[0] == 'MemTotal'
      free_mem = val[1].strip.to_i if val[0] == 'MemFree'
      total_swap = val[1].strip.to_i if val[0] == 'SwapTotal'
      free_swap = val[1].strip.to_i if val[0] == 'SwapFree'
      buffer_mem = val[1].strip.to_i if val[0] == 'Buffers'
      cache_mem = val[1].strip.to_i if val[0] == 'Cached'
      shared_mem = val[1].strip.to_i if val[0] == 'MemShared'
    }

    memused = total_mem - free_mem - cache_mem - buffer_mem
    swapused = total_swap - free_swap

    mem_info = {}
    mem_info[:swapused] = swapused / 1024
    mem_info[:swaptotal] = total_swap / 1024
    mem_info[:used] = memused / 1024
    mem_info[:total] = total_mem / 1024

    return mem_info
  end

  def Server.cpu_info(res)
    
    total = 0
    name = ''
    mhz = ''

    res.each { |memitem|
      val = memitem.split(':')
      s = val[1]
      val[0].strip!
      total = total + 1 if val[0] == 'processor'
      name = val[1].strip if val[0] == 'model name'
      mhz = val[1].strip if val[0] == 'cpu MHz' 
    }

    cpu_data = {}
    cpu_data[:total] = total
    cpu_data[:name] = name.squeeze(' ')
    cpu_data[:mhz] = mhz
    return cpu_data
  end
  
  def Server.drive_info(res)

    xml = ''
    first = true

    res.each { |drive|
      entry = drive.split(' ')
xml += <<EOF
    <drive>
      <path>#{entry[5]}</path>
      <totalspace>#{entry[1]}</totalspace>
      <usedspace>#{entry[2]}</usedspace>
      <percent>#{entry[4]}</percent>
    </drive>
EOF
      if first # Skip the first line
        first = false
        xml = ''
      end
    }

    return xml
  end

  def Server.load_info(res)
    val = res.split(' ')
    return [val[0].to_f, val[1].to_f, val[2].to_f]
  end
  
  def Server.distribution(dist)
    if dist.count("No such file") > 0
      return "Debian"
    end
    return dist
  end
  
  def Server.bandwidth_info(res)
    # Comes through looking like :-
    # lo:345345 345345
    # vnet0:345345 46456
    
    tx = 0
    rx = 0
    res.each { |bandwidth|
      tx = tx + bandwidth.split(" ")[1].to_i
      rx = rx + bandwidth.split(" ")[0].split(":")[1].to_i
    }
    
    band = { :tx => tx, :rx =>  rx }
  end

  def retrieve_stats(decrypt_pass = false)
    if ssh_connection? or self.url == nil
      return retrieve_stats_ssh(decrypt_pass)
    else
      return retrieve_stats_agent
    end
  end

  def retrieve_stats_agent

    begin

      response,body = xml_data = Net::HTTP.get_response(
        URI.parse(self.url + '?cmd=stats'))

      if response.kind_of? Net::HTTPSuccess

        doc = REXML::Document.new(body)

        if doc.root.elements['processing'] == nil
          errors.add_to_base 'Unable to parse results from agent'
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
      else
        errors.add_to_base 'Could not access URL'
      end

    rescue Exception => e
      errors.add_to_base 'Unable to connect ' + e.to_s
    end

    return errors.empty?
  end

  def retrieve_stats_ssh(decrypt_pass = false)
    commands = ['cat /etc/*-release', CMD_LOAD_AVG,
      'cat /etc/*_version', 'uname -r', 'cat /proc/meminfo',
      'cat /proc/cpuinfo', CMD_BANDWIDTH]
      
    results = execute_ssh(commands, decrypt_pass)
   
    if results.kind_of? String
      errors.add_to_base results
    else
      load_data = Server.load_info results['cat /proc/loadavg']
      memory_data = Server.memory_info results['cat /proc/meminfo']
      bandwidth_data = Server.bandwidth_info results[CMD_BANDWIDTH]
      cpu_data = Server.cpu_info results['cat /proc/cpuinfo']
      self.distro = Server.distribution results['cat /etc/*-release']
      self.kernelver = results['uname -r']
      self.platform = results['cat /etc/*_version']
      self.cpuload = load_data[0]
      self.usedmem = memory_data[:used]
      self.totalmem = memory_data[:total]
      self.usedswap = memory_data[:swapused]
      self.totalswap = memory_data[:swaptotal]
      self.last_tx = bandwidth_data[:tx]
      self.last_rx = bandwidth_data[:rx]
      self.cpucount = cpu_data[:total]
      self.cpumhz = cpu_data[:mhz]
      self.cpu =  cpu_data[:name]
    end
    
    return errors.empty?
  end
  
  def execute_ssh(commands, decrypt_pass = false) 
    begin
    
      results = {}
      key_data = []
      if private_key != nil
        key_data = [decode_private_key]
      end

      pass = password
      if decrypt_pass
        pass = Encryptor.decrypt(:value => Base64.decode64(pass), 
          :key => JAKE_KEY)
      end
    
      Timeout::timeout(4) do
        begin
          Net::SSH.start( hostname, username, 
            :key_data => key_data,
            :password => pass, :port => ssh_port ) do |ssh|
            
            commands.each { |command|
              results[command] = ssh.exec!(command)
            }
          end  
        rescue Net::SSH::HostKeyMismatch => e
          e.remember_host!
          retry
        rescue Net::SSH::AuthenticationFailed => e
          return "Failed Authentication"
        rescue StandardError => e
          return e.to_s
        end
      end
    
      return results
    
    rescue Timeout::Error
      return "Timed out trying to get a connection"
    end
  end

  private

  def generate_keys(account_id)
    kc = Rails.cache.fetch("next_private_key#{account_id}") do
      kc = Keychain.find(rand(Keychain.count) + 1)
    end
    self.public_key = kc.public_key
    self.private_key = kc.private_key
  end

  def decode_private_key
    return Encryptor.decrypt(:value => Base64.decode64(self.private_key),
      :key => JAKE_KEY)
  end

  def clear_private_key(id)
    Rails.cache.delete("next_private_key#{id}")
  end

  def encrypt_fields

    if password_changed? and !password.empty?
      p = Encryptor.encrypt(:value => self.password, 
        :key => JAKE_KEY)
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
