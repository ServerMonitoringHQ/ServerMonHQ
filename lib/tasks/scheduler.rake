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
        check_heartbeat(sm, 'Not heard from agent for a while.')
      end
    end
  end
end

desc "This task is called by the Heroku scheduler add-on" 
task :run_notification_cron => :environment do
  MonitorUser.active.each do |um|
    process_new_incidents(um)
    process_resolved_incidents(um)
  end
end