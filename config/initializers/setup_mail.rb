ActionMailer::Base.smtp_settings = { 
  :address => "smtp.sendgrid.net",  
  :port => 25,  
  :domain => 'serverpulsehq.com',  
  :authentification => :plain,
  :user_name => 'ian.purton@gmail.com',
  :password => 'vja481xsen' 
}
