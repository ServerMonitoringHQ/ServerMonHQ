desc "This task is called by the Heroku scheduler add-on" 
task :remove_resolved_incidents => :environment do     
  Incident.destroy_all(['created_at <= ? and open = ?', 1.days.ago.beginning_of_day, false])
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
        MonitorcronController.check_heartbeat(sm, 'Not heard from agent for a while.')
      end
    end
  end
end

desc "This task is called by the Heroku scheduler add-on" 
task :run_notification_cron => :environment do
  MonitorUser.active.each do |um|
    NotificationcronController.process_new_incidents(um)
    NotificationcronController.process_resolved_incidents(um)
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