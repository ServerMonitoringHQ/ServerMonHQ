class MonitorcronController < ApplicationController

  def  monitor_cron
    @servers = Server.active
    @servers.sort_by {rand} #  Randomize the array, give everyone a fair chnace

    @servers.each do |server|
      server.pages.each do |page|
        Resque.enqueue(ServerMonitoringHQ::Jobs::Page,
          page.url,
          page.search_text,
          page.id,
          return_url,
          Time.now.gmtime,
          Rails.env
        )
      end

      # If the server hasn't been updated in a while it's probably down.
      if server.updated_at < 1.minute.ago

        server.serverdown = true
        if server.down_mins == nil
          server.down_mins = 0
        end
        server.down_mins = server.down_mins + 1
        ActiveRecord::Base.record_timestamps = false
        server.save(:validate=> false)
        ActiveRecord::Base.record_timestamps = true
      end

      server.monitor_servers.each do |sm|
        next if !sm.server.totalmem || sm.measure.paused
        if sm.measure.notify_heartbeat?
          check_heartbeat(sm, 'Not heard from agent for a while.')
        end
      end


    end

    render :layout => false

  end 

  def receive_page
  
    if params[:page]
      page = Page.find(params[:page][:id].to_i)
      page.status = params[:page][:status].to_i
      page.last_error = params[:page][:error]
      page.save
    end

    render :text => "OK"  
  end

  def receive_ports(params, server_id)

    if params[:status][:ports]
      ports = params[:status][:ports][:port]
      ports = [ports] unless ports.is_a?(Array)
      ports.each { |port|
        p = Port.where(:address => port[:address].to_i, 
          :server_id => server_id).first
        if p != nil
          p.status = port[:status].to_i
          p.save
        end
      }
    end
  end

  def receive_memory
    if params[:memory]
      server = Server.find(params[:memory][:id].to_i)

      server.usedswap = params[:memory][:swapused].to_f
      server.totalswap = params[:memory][:swaptotal].to_f

      server.usedmem = params[:memory][:used].to_f
      server.totalmem = params[:memory][:total].to_f

      server.save(:validate=> false)
    end
    render :text => "OK"  
  end

  def receive_top(params, server)
    if params[:status][:top]
      server.top = params[:status][:top]

      server.save(:validate=> false)
    end
  end

  def receive_monitor

    server = nil
    msg = nil

    if params[:error]
      server = Server.find(params[:error][:id].to_i)
      msg = params[:error][:message]
      server.serverdown = true
      if server.down_mins == nil
        server.down_mins = 0
      end
      server.down_mins = server.down_mins + 1
      server.save(:validate=> false)
    end

    if params[:status]
      if params[:status][:access_key]
        server = Server.find_by_access_key(params[:status][:access_key])
        params[:status][:id] = server.id
      else
        server = Server.find(params[:status][:id].to_i)
      end

      # Do we have some down time to log ?
      downtime = 0
      if server.serverdown
        downtime = server.down_mins
        server.down_mins = 0
      end
      server.serverdown = false
      server.usedswap = params[:status][:memory][:swapused].to_f
      server.totalswap = params[:status][:memory][:swaptotal].to_f

      server.usedmem = params[:status][:memory][:used].to_f
      server.totalmem = params[:status][:memory][:total].to_f

      server.cpuload = params[:status][:load][:load1].to_f
      server.cpumhz = params[:status][:cpuinfo][:cpumhz]
      server.cpu = params[:status][:cpuinfo][:cpu]
      server.cpucount = params[:status][:cpuinfo][:cpucount]

      server.apacheversion = params[:status][:apacheversion]
      server.platform = params[:status][:platform]
      server.distro = params[:status][:release]
      server.phpversion = params[:status][:phpversion]
      if params[:status][:version] != nil
        server.kernelver = params[:status][:version][0]
      end
      server.uptime = params[:status][:uptime].to_i

      tx_diff = 0
      tx = params[:status][:bandwidth][:tx].to_i 
      if server.last_tx != nil
        if tx < server.last_tx
          tx_diff = (4294967296 - server.last_tx) + tx
        else
          tx_diff = tx - server.last_tx
        end
      end
      server.last_tx = tx

      rx_diff = 0
      rx = params[:status][:bandwidth][:rx].to_i 
      if server.last_rx != nil
        if rx < server.last_rx
          rx_diff = (4294967296 - server.last_rx) + rx
        else
          rx_diff = rx - server.last_rx
        end
      end
      server.last_rx = rx

      server.save(:validate=> false)

      receive_drives(params, server.id)
      receive_ports(params, server.id)

      load = ((server.cpuload / server.cpucount) * 100) rescue 0
      load = 0 if load.nan?
      mem = ((server.usedmem / server.totalmem) * 100) rescue 0
      mem = 0 if mem.nan?
      swap = ((server.usedswap / server.totalswap) * 100) rescue 0
      swap = 0 if swap.nan?

      Time.zone = 'UTC'

      update_history(server, '24HR', Time.zone.now.hour, mem,
        swap, tx_diff, rx_diff, load, downtime)
      update_history(server, 'WEEK', Time.zone.now.wday, mem,
        swap, tx_diff, rx_diff, load, downtime)
      update_history(server, 'MONTH', Time.zone.now.month, mem,
        swap, tx_diff, rx_diff, load, downtime)

 
    end

    @memory = []
    @load = []
    @pages = []
    @ports = []
    @drives = []

    server.monitor_servers.each do |sm|
      next if !sm.server.totalmem || sm.measure.paused
      if sm.measure.notify_mem?
        @memory << check_memory(sm)
      end
      if sm.measure.notify_load?
        @load << check_load(sm)
      end
      if sm.measure.notify_pages?
        @pages << check_pages(sm)
      end
      if sm.measure.notify_ports?
        @ports << check_ports(sm)
      end
      if sm.measure.notify_disk?
        @drives << check_drives(sm)
      end
      if sm.measure.notify_heartbeat?
        check_heartbeat(sm, msg)
      end
      if sm.measure.notify_bandwidth?
        check_bandwidth(sm)
      end
    end

    render :text => "OK"  
  
  end

  def receive_drives(params, server_id)
    if params[:status][:drives] and 
      params[:status][:drives].class.name != 'String'

      Server.find(server_id).disks.clear

      drives = params[:status][:drives][:drive]
      drives = [drives] unless drives.is_a?(Array)
      drives.each { |drive|
        continue if drive[:path] == ''
        d = Disk.new
        d.path = drive[:path]
        d.server_id = server_id
        d.usedspace = drive[:usedspace]
        d.totalspace = drive[:totalspace]
        d.percent = drive[:percent]
        d.save
      }
    end

  end

  private

  def check_ports(sm)

    info = {}
    info[:name] = sm.server.name

    down_pages = sm.server.ports.where(:status => 0)

    info[:ports] = down_pages.length

    if down_pages.length > 0
      raise_incident(sm.server.account_id, sm.server.id,
        sm.measure.id, Incident::PORT_ERROR,
          "At least one port is down")
    else
      clear_incident(sm.server.account_id, sm.server.id,
        sm.measure.id, Incident::PORT_ERROR)
    end

    return info
  end

  def check_pages(sm)

    info = {}
    info[:name] = sm.server.name

    down_pages = sm.server.pages.where(:status => 0)

    info[:pages] = down_pages.length

    if down_pages.length > 0
      raise_incident(sm.server.account_id, sm.server.id,
        sm.measure.id, Incident::PAGE_ERROR,
          "At least one page is down")
    else
      clear_incident(sm.server.account_id, sm.server.id,
        sm.measure.id, Incident::PAGE_ERROR)
    end

    return info
  end

  def check_heartbeat(sm, msg)

    if sm.server.serverdown
      raise_incident(sm.server.account_id, sm.server.id,
        sm.measure.id, Incident::SERVER_DOWN, 
        'The server is not responding : ' + msg)
    else
      clear_incident(sm.server.account_id, sm.server.id,
      sm.measure.id, Incident::SERVER_DOWN)
    end
  end

  def check_bandwidth(sm)

    total = sm.measure.bandwidth
    if total == nil
      return
    end
    
    case
    when sm.measure.bandwidth_scale == 'MB'
      total = total * 1048576
    when sm.measure.bandwidth_scale == 'GB'
      total = total * 1048576 * 1024
    when sm.measure.bandwidth_scale == 'TB'
      total = total * 1048576 * 1024 * 1024
    end
    
    time = '24HR'
    case
    when sm.measure.bandwidth_time == '1 Week'
      time = 'WEEK'
    when sm.measure.bandwidth_time == '1 Month'
      time = 'MONTH'
    end

    used = sm.server.histories.sum(:bandwidth_tx, :conditions => ['name = ?', time])

    if used > total
      raise_incident(sm.server.account_id, sm.server.id,
        sm.measure.id, Incident::HIGH_BANDWIDTH,
          bandwidth_desc(used, total))
    else
      clear_incident(sm.server.account_id, sm.server.id,
        sm.measure.id, Incident::HIGH_BANDWIDTH)
    end

  end

  def check_load(sm)

    info = {}
    info[:name] = sm.server.name

    perc_load = (sm.server.cpuload / 1.0) * 100
    info[:load_calc] = perc_load
    info[:load_perc] = sm.measure.load_perc

    if perc_load > sm.measure.load_perc
      raise_incident(sm.server.account_id, sm.server.id,
        sm.measure.id, Incident::HIGH_LOAD,
          load_desc(perc_load, sm.measure.load_perc))
    else
      clear_incident(sm.server.account_id, sm.server.id,
      sm.measure.id, Incident::HIGH_LOAD)
    end

    return info
  end

  def check_drives(sm)

    info = {}
    info[:name] = sm.server.name

    drive_full = false
    sm.server.disks.each do |drive|
      drive_full = true if drive.percent.to_i > sm.measure.disk_perc
    end

    if drive_full
      raise_incident(sm.server.account_id, sm.server.id,
        sm.measure.id, Incident::DISK_LIMIT,
          disk_desc(sm.measure.disk_perc))
    else
      clear_incident(sm.server.account_id, sm.server.id,
      sm.measure.id, Incident::DISK_LIMIT)
    end

    return info
  end

  def check_memory(sm)

    info = {}
    info[:name] = sm.server.name

    perc_mem = (sm.server.usedmem / sm.server.totalmem) * 100
    info[:mem_calc] = perc_mem
    info[:mem_perc] = sm.measure.mem_perc

    if perc_mem > sm.measure.mem_perc
      raise_incident(sm.server.account_id, sm.server.id,
        sm.measure.id, Incident::HIGH_MEMORY,
          memory_desc(sm.server.usedmem, sm.server.totalmem,
            perc_mem, sm.measure.mem_perc))
    else
      clear_incident(sm.server.account_id, sm.server.id,
      sm.measure.id, Incident::HIGH_MEMORY)
    end

    return info
  end

  def memory_desc(usedmem, totalmem, perc, threshold)
    p = "%.1f" % perc

    return "Memory is at " + p + "% this is greater than" +
      " monitor threshold of #{threshold}%"
  end

  def disk_desc(threshold)

    return "At least 1 disk is using more than {threshold}% of space."
  end

  def bandwidth_desc(total, threshold)
  return "Bandwidth usage is at #{total} which is greater than #{threshold}"
  end

  def load_desc(perc, threshold)
    p = "%.1f" % perc

    return "Load is at " + p + "% this is greater than" +
      " monitor threshold of #{threshold}%"
  end

  def raise_incident(account_id, server_id, measure_id, type, desc)

    incident = Incident.where(
      'account_id = ? AND server_id = ? AND measure_id = ? AND incident_type = ? AND open = ?',
      account_id, server_id, measure_id, type, true).first

    unless incident
      incident = Incident.new
      incident.incident_type = type
      incident.account_id = account_id
      incident.description = desc
      incident.server_id = server_id
      incident.measure_id = measure_id
      incident.open = true
      incident.save
    end
  end

  def clear_incident(account_id, server_id, measure_id, type)

    incident = Incident.where(
      'account_id = ? AND server_id = ? AND measure_id = ? AND incident_type = ? AND open = ?',
      account_id, server_id, measure_id, type, true).first

    if incident
      incident.open = false
      incident.save
    end
  end

  # start_time and end_time can be minutes, hours or days.
  # Say for example hourly monitoring, if the minute now is less than the last minute
  # that was monitored we reset the hour as it looks like we've entered a new hour.

  def update_history(server, name, slot, mem, swap, tx, rx, cpu, downtime)

    history = server.histories.where("name = '#{name}' AND slot = #{slot}").first

    if history == nil
      history = server.histories.new
      history.name = name
      history.slot = slot
    else
      check_for_reset(name, history)
    end

    if history.down_mins == nil
      history.down_mins = 0
    end
    history.down_mins = history.down_mins + downtime

    history.cpu_total = history.cpu_total + cpu.to_i
    history.cpu_lo = cpu if history.cpu_lo > cpu or history.cpu_lo == 0
    history.cpu_hi = cpu unless history.cpu_hi > cpu
    history.cpu_count = history.cpu_count + 1

    history.mem_lo = mem.to_f if history.mem_lo > mem.to_f or history.mem_lo == 0
    history.mem_hi = mem unless history.mem_hi > mem
    history.mem_total = history.mem_total + mem
    history.mem_count = history.mem_count + 1

    history.swap_lo = swap if history.swap_lo > swap or history.swap_lo == 0
    history.swap_hi = swap unless history.swap_hi > swap
    history.swap_total = history.swap_total + swap
    history.swap_count = history.swap_count + 1

    history.bandwidth_tx = history.bandwidth_tx + tx.to_i
    history.bandwidth_rx = history.bandwidth_rx + rx.to_i

    history.save
  end

  def check_for_reset(name, history)

    if name == '24HR' and history.updated_at > 1.hour.ago
      return
    end

    if name == 'WEEK' and history.updated_at > 1.day.ago
      return
    end

    if name == 'MONTH' and history.updated_at > 1.week.ago
      return
    end

    history.mem_lo = 0
    history.mem_hi = 0
    history.mem_total = 0
    history.mem_count = 0

    history.swap_lo = 0
    history.swap_hi = 0
    history.swap_total = 0
    history.swap_count = 0

    history.cpu_lo = 0
    history.cpu_hi = 0
    history.cpu_total = 0
    history.cpu_count = 0

    history.bandwidth_tx = 0
    history.bandwidth_rx = 0
  end
end
