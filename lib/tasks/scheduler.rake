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
      :email => 'ian.purton@rbs.com'
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
      :email => 'ian.purton@rbs.com'
    }
    ticket = sirportly.create_ticket(properties)
    ticket.post_update(:message => 'Trial ends in 3 days.')
  }
  users = User.where('created_at >= ?and created_at <= ?', 7.days.ago.beginning_of_day, 7.days.ago.end_of_day)
  puts users
end
