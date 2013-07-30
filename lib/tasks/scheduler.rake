desc "This task is called by the Heroku scheduler add-on" 
task :remove_resolved_incidents => :environment do     
  Incident.destroy_all(['created_at <= ? and open = ?', 1.days.ago.beginning_of_day, false])
end

desc "This task is called by the Heroku scheduler add-on" 
task :send_usage_statistics => :environment do     
  FlyingV.post(Date.today.strftime("SMHQ-Signups-%B-%Y"), User.where('created_at >= ?', Date.today.at_beginning_of_month).count.to_s)
  FlyingV.post(Date.today.strftime("SMHQ-Servers-Commissioned-%B-%Y"), Server.where('created_at >= ? and uptime is not NULL', Date.today.at_beginning_of_month).count.to_s)
end

desc "This task is called by the Heroku scheduler add-on" 
task :registered_7_days => :environment do     
  accounts = Account.where('created_at >= ? and created_at <= ?', 7.days.ago.beginning_of_day, 7.days.ago.end_of_day)
  sirportly = Sirportly::Client.new('5040678f-a2bb-119c-150b-649cc531c2f9', 
    'g9j701xoohucklcabhyb2klaulkmkri5yjlkutwfkz3s9cwc12')
  accounts.each { |account|
    user = account.users.find(:first)

    if user == nil then
      next
    end

    properties = {   
      :brand => 'ServerMonitoringHQ.com',   
      :department => 'Technical Support',   
      :status => 'New',   
      :priority => 'Normal',   
      :subject => 'ServerMonitoringHQ.com',   
      :user => 'ianpurton',
      :name => user.first_name + ' ' + user.last_name,   
      :email => user.email
    }
    ticket = sirportly.create_ticket(properties)
    ticket.post_update(:message => 'User has been on trial for 7 days.')
  }
end

desc "This task is called by the Heroku scheduler add-on" 
task :free_trial_end => :environment do     
  accounts = Account.where('trial_end >= ? and trial_end <= ?', 
    (Time.now + 3.days).beginning_of_day, (Time.now + 3.days).end_of_day)
  sirportly = Sirportly::Client.new('5040678f-a2bb-119c-150b-649cc531c2f9', 
    'g9j701xoohucklcabhyb2klaulkmkri5yjlkutwfkz3s9cwc12')
  accounts.each { |account|
    puts "Account " + account.id.to_s
    user = account.users.find(:first)

    if user == nil then
      next
    end

    properties = {   
      :brand => 'ServerMonitoringHQ.com',   
      :department => 'Technical Support',   
      :status => 'New',   
      :priority => 'Normal',   
      :subject => 'ServerMonitoringHQ.com',   
      :user => 'ianpurton',
      :name => user.first_name + ' ' + user.last_name,   
      :email => user.email
    }
    ticket = sirportly.create_ticket(properties)
    ticket.post_update(:message => 'Trial ends in 3 days.')
  }
  users = User.where('created_at >= ?and created_at <= ?', 7.days.ago.beginning_of_day, 7.days.ago.end_of_day)
  puts users
end

desc "This task is called by the Heroku scheduler add-on" 
task :run_monitor_cron => :environment do
  @servers = Server.active
  @servers.sort_by {rand} #  Randomize the array, give everyone a fair chnace

  @servers.each do |server|

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
end


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

  return "At least 1 disk is using more than #{threshold}% of space."
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

desc "This task is called by the Heroku scheduler add-on" 
task :run_notification_cron => :environment do
  MonitorUser.active.each do |um|
    process_new_incidents(um)
    process_resolved_incidents(um)
  end
end

def send_text(to, message)

  account_sid = 'AC1d6be5fe338cad384648a39aa2354f0f'
  auth_token = 'bf0aebbd2c61e00829508cc5ffa17d10'

  client = Twilio::REST::Client.new account_sid, auth_token

  client.account.sms.messages.create(
    :from => '+19546211201',
    :to => to,
    :body => message
  )

end

def process_resolved_incidents(um)

  # Find all resolved incidents less than 48 hours old
  incidents = Incident.where(
    'measure_id = ? AND open = ? AND updated_at > ?',
    um.measure_id, false, 48.hours.ago)

  resolved_incidents = []
  incidents.each do |incident|
    incident_notification = IncidentNotification.where(
      'incident_id = ? AND user_monitor_id = ?',
      incident.id, um.id).first

    # Do we have a notification for this incident ?
    if incident_notification != nil
      incident_notification.destroy
      resolved_incidents << incident
    end
  end

  # If we have new incidents send an email
  if resolved_incidents.length > 0
    if um.notify_type == 0 or um.notify_type == 2
      NotificationMailer.alert_service_restored(um, resolved_incidents).deliver
    end
    if um.notify_type == 1 or um.notify_type == 2
      msg = "ServerMonitoringHQ.com #{resolved_incidents.length} new incident(s) resolved"
      resolved_incidents.each { |incident|
        msg += "\n#{incident.server.name} (#{incident.description}) - Resolved"
      }
      send_text(um.user.mobile_number, msg)
    end
  end
end

def process_new_incidents(um)

  # Find all open incidents for the user older than the users wait_for
  incidents = Incident.where(
    'measure_id = ? AND open = ? AND created_at < ?',
    um.measure_id, true, um.wait_for.minutes.ago)

  new_incidents = []
  incidents.each do |incident|
    incident_notification = IncidentNotification.where(
      'incident_id = ? AND user_monitor_id = ?',
      incident.id, um.id).first

    # Do we already have a notification for this incident ?
    if incident_notification == nil
      inot = IncidentNotification.new
      inot.incident_id = incident.id
      inot.user_monitor_id = um.id
      inot.save
      new_incidents << incident
    end
  end
  # If we have new incidents send an email
  if new_incidents.length > 0
    if um.notify_type == 0 or um.notify_type == 2
      NotificationMailer.alert_service_down(um, new_incidents).deliver
    end
    if um.notify_type == 1 or um.notify_type == 2
      msg = "ServerMonitoringHQ.com #{new_incidents.length} new incident(s)"
      new_incidents.each { |incident|
        msg += "\n#{incident.server.name} - #{incident.description}"
      }
      send_text(um.user.mobile_number, msg)
    end
  end
end
