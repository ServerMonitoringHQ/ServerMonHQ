ActionMailer::Base.smtp_settings = { 
  :address => "smtp.sendgrid.net",  
  :port => 25,  
  :domain => 'servermonitoringhq.com',  
  :user_name => 'ian.purton@gmail.com',
  :password => 'vja481xsen',
  :port => 587,  
  :authentication => :plain,   
  :enable_starttls_auto => true
}
