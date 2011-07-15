module SysStats

  require 'net/ssh'
  require 'yaml'
  require 'net/http'
  require 'open-uri'
  require 'encryptor'
  require 'base64'

  class Stats

    CMD_MEMORY = 'cat /proc/meminfo'
    CMD_CPU = 'cat /proc/cpuinfo'
    CMD_LOAD = 'cat /proc/loadavg'
    CMD_DRIVES = 'df -h'
    CMD_DISTRO = 'cat /etc/*-release'
    CMD_VERSION1 = 'cat /etc/*_version'
    CMD_VERSION2 = 'uname -r'
    CMD_PLATFORM = 'uname -m'
    CMD_UPTIME = 'cat /proc/uptime' 
    CMD_PHP = 'php -v'
    CMD_MYSQL = 'mysql -e status|grep "Server version"' 
    CMD_APACHE = '/usr/bin/apache2ctl -v' 
    CMD_BANDWIDTH = "cat /proc/net/dev | grep '^.*[^lo]:' | awk '{print $1, $9 }'"
    CMD_TOP = "top -b -n 1 | head -n 27 | tail -n 22"
    CMD_LOG = "tail -n 20 [path] 2>&1"
    CMD_NETSTAT = "netstat -ln"
    JAKE_PURTON='Jake Purton, 18/8/2006'

    def encrypt_pass(pass)
      return Base64.encode64(Encryptor.encrypt(:value => pass,  :key => JAKE_PURTON))
    end

    def memory(hostname, username, password, ssh_port, id, private_key, return_url)

      xml = memory(hostname, username, password, ssh_port, id, private_key)
      url = URI.parse(return_url + 'receive_memory')
      http = Net::HTTP.new(url.host, url.port)
      response,body = http.post(url.path, xml, {'Content-type'=>'text/xml;charset=utf-8'})
      LOG.info response
    end

    def memory(hostname, username, password, ssh_port, id, private_key)

      commands = [CMD_MEMORY]

      results = execute_ssh(commands, hostname, username, password, ssh_port, private_key)
        
      if results.kind_of? String
        return create_error_xml(results, id)
      end
      
      memory_data = memory_info results[CMD_MEMORY]
xml = <<EOF
<memory>
  <id>#{id}</id>
  <total>#{memory_data[:total]}</total>
  <swaptotal>#{memory_data[:swaptotal]}</swaptotal>
  <used>#{memory_data[:used]}</used>
  <swapused>#{memory_data[:swapused]}</swapused>
</memory>
EOF
      xml
    end

    def top(hostname, username, password, ssh_port, id, private_key, return_url)
      xml = top(hostname, username, password, ssh_port, id, private_key)
      url = URI.parse(return_url + 'receive_top')
      http = Net::HTTP.new(url.host, url.port)
      response,body = http.post(url.path, xml, {'Content-type'=>'text/xml;charset=utf-8'})
      LOG.info response
    end

    def top(hostname, username, password, ssh_port, id, private_key)

      commands = [CMD_TOP, CMD_LOAD]

      results = execute_ssh(commands, hostname, username, password, ssh_port, private_key)
        
      if results.kind_of? String
        return create_error_xml(results, id)
      end
      load_data = load_info results[CMD_LOAD]
      
xml = <<EOF
<top>
  <id>#{id}</id>
  <top>#{results[CMD_TOP].gsub(/</, '&lt;')}</top>
  <load>
    <load1>#{load_data[0]}</load1>
    <load2>#{load_data[1]}</load2>
    <load3>#{load_data[2]}</load3>
  </load>
</top>
EOF
      return xml
    end

    def load_info(res)
      val = res.split(' ')
      return [val[0].to_f, val[1].to_f, val[2].to_f]
    end

    def create_error_xml(results, id)
xml = <<EOF
<error>
  <id>#{id}</id>
  <message>#{results}</message>
</error>
EOF

      return xml

    end

    def live_stats_xml(hostname, username, password, ssh_port, id, private_key)

      commands = [CMD_MEMORY, CMD_CPU,
        CMD_LOAD, CMD_DRIVES, CMD_DISTRO, CMD_PLATFORM,
        CMD_VERSION1, CMD_VERSION2, CMD_UPTIME,
        CMD_PHP, CMD_MYSQL, CMD_APACHE, CMD_BANDWIDTH]
        
      begin
        results = execute_ssh(commands, hostname, username, password, ssh_port, private_key)
      rescue Exception => e
        LOG.error 'SSH error ' + e.to_s
      end
        
      if results.kind_of? String
        return create_error_xml(results, id)
      end
          
      memory_data = memory_info results[CMD_MEMORY]
      cpu_data = cpu_info results[CMD_CPU]
      load_data = load_info results[CMD_LOAD]
      drive_data = drive_info results[CMD_DRIVES]
      dist = distribution results[CMD_DISTRO]
      bandwidth_data = bandwidth_info results[CMD_BANDWIDTH]
      results[CMD_PHP] = results[CMD_PHP][0, 255]

      version = results[CMD_VERSION1]
      if version.index('No such file') != 0
        version = results[CMD_VERSION2]
      end
          
xml = <<EOF
<status>
  <id>#{id}</id>
  <cpuinfo>
    <cpu>#{cpu_data[:name]}</cpu>
    <cpucount>#{cpu_data[:total]}</cpucount>
    <cpumhz>#{cpu_data[:mhz]}</cpumhz>
  </cpuinfo>
  <memory>
    <total>#{memory_data[:total]}</total>
    <swaptotal>#{memory_data[:swaptotal]}</swaptotal>
    <used>#{memory_data[:used]}</used>
    <swapused>#{memory_data[:swapused]}</swapused>
  </memory>
  <load>
    <load1>#{load_data[0]}</load1>
    <load2>#{load_data[1]}</load2>
    <load3>#{load_data[2]}</load3>
  </load>
  <mysql>#{results[CMD_MYSQL]}</mysql>
  <phpversion>#{results[CMD_PHP]}</phpversion>
  <apacheversion>#{results[CMD_APACHE]}</apacheversion>
  <uptime>#{results[CMD_UPTIME].split(' ')[0]}</uptime>
  <bandwidth>
    <tx>#{bandwidth_data[:tx]}</tx> 
    <rx>#{bandwidth_data[:rx]}</rx>
  </bandwidth>
  <release>#{dist}</release>
  <version>#{version}</version>
  <platform>#{results[CMD_PLATFORM]}</platform>
  <drives>
#{drive_data}  </drives>
</status>
EOF
     
      return xml

    end

    def execute_ssh(commands, hostname, username, password, ssh_port, private_key) 
      begin
        
        results = {}
        key_data = []

        if private_key != nil
          key_data = [Encryptor.decrypt(:value => Base64.decode64(private_key), 
            :key => JAKE_PURTON)]
        end
       
        ssh_params = { :port => ssh_port, :key_data => key_data }

        if password != nil and !password.empty?
          password = Encryptor.decrypt(:value => Base64.decode64(password), 
              :key => JAKE_PURTON)
          ssh_params[:password] = password
        end

        Timeout::timeout(5) do
          begin
            Net::SSH.start( hostname, username, ssh_params) do |ssh|
              
              commands.each { |command|
                results[command] = ssh.exec!(command)
                results[command].gsub!(/stdin: is not a tty/, '')
              }
            end  
          rescue Net::SSH::HostKeyMismatch => e
            e.remember_host!
            retry
          rescue Net::SSH::AuthenticationFailed => e
            return "Failed Authentication"
          rescue StandardError => e
            LOG.info e.to_s
            LOG.info e.backtrace
            return "Error " + e.to_s + ' ' + username + '@' + hostname +  ':' + ssh_port
          end
        end
        return results
        
      rescue Timeout::Error
        LOG.error "Timed out trying to get a connection " + hostname
        return "Timed out trying to get a connection"
      end
    end
      
    def memory_info(res)
        
      total_mem = 0
      free_mem = 0
      total_swap = 0
      free_swap = 0
      buffer_mem = 0
      cache_mem = 0
      shared_mem = 0

      res.each_line { |memitem|
        val = memitem.split(':')
        s = val[1]

        if s == nil
          next
        end

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

    def cpu_info(res)
       
      total = 0
      name = ''
      mhz = ''

      res.each_line { |memitem|
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
      
    def load_info(res)
      val = res.split(' ')
      return [val[0].to_f, val[1].to_f, val[2].to_f]
    end
      
    def bandwidth_info(res)
      # Comes through looking like :-
      # lo:345345 345345
      # vnet0:345345 46456
        
      tx = 0
      rx = 0
      res.each_line { |bandwidth|
        tx = tx + bandwidth.split(" ")[1].to_i
        rx = rx + bandwidth.split(" ")[0].split(":")[1].to_i
      }
        
      band = { :tx => tx, :rx =>  rx }
    end 
      
    def drive_info(res)

      xml = ''
      first = true

      res.each_line { |drive|
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

    def load_info(res)
      val = res.split(' ')
      return [val[0].to_f, val[1].to_f, val[2].to_f]
    end
      
    def distribution(dist)
      if dist.count("No such file") > 0
        return "Debian"
      end
      return dist
    end
      
    def page(url, search_text, id, return_url)

      status = 0
      error = ''
      begin
      Timeout::timeout(15) do
        begin
          html = open(url).read
          status = 1
          if search_text != nil and ! search_text.empty?
            if html[search_text]  == nil
              error = 'Search string not found'
              status = 0
            end
          end
        rescue Exception => e
          status = 0
          error = e.to_s
        end
      end
      rescue Timeout::Error
        error = 'Timed out trying to retrieve page.'
        LOG.error error
        status = 0
      end

      LOG.info url + ' ' + status.to_s
      xml = ''

xml += <<EOF
  <page>
    <id>#{id}</id>
    <status>#{status}</status>
    <error>#{error}</error>
  </page>
EOF
      url = URI.parse(return_url + 'receive_page')
      http = Net::HTTP.new(url.host, url.port)
      response,body = http.post(url.path, xml, {'Content-type'=>'text/xml;charset=utf-8'})
      LOG.info response

    end

    def ports(hostname, username, password, ssh_port, id, ports, private_key, return_url)

      commands = [CMD_NETSTAT]

      results = execute_ssh(commands, hostname, username, password, ssh_port, private_key)
        
      if results.kind_of? String
        return create_error_xml(results, id)
      end

      ns = results[CMD_NETSTAT]

      p = ports.split(/,/)
      xml = "<ports><id>#{id}</id>"

      status = 0
      p.each { |port|
        if ns.index(':' + port.to_s) != nil
          status = 1
        end
    xml += <<EOF
<port>
  <address>#{port}</address>
  <status>#{status}</status>
</port>
EOF
      }
      xml += '</ports>'

      url = URI.parse(return_url + 'receive_ports')
      http = Net::HTTP.new(url.host, url.port)
      response,body = http.post(url.path, xml, {'Content-type'=>'text/xml;charset=utf-8'})
      LOG.info response

    end

    def monitor_url(url, id, return_url)

      begin
        response,data = Net::HTTP.get_response(
          URI.parse(url + '?cmd=stats'))

        LOG.info 'Agent = ' + url

        data.gsub!(/THE_ID/, id.to_s)

        if response.kind_of? Net::HTTPSuccess
          url = URI.parse(return_url + 'receive_monitor')
          http = Net::HTTP.new(url.host, url.port)
          response,body = http.post(url.path, data, {'Content-type'=>'text/xml;charset=utf-8'})
          LOG.info response
        end

      rescue Exception => e
        LOG.info 'Unable to connect (monitor_url) ' + e.to_s
      end
    end

  end
end
