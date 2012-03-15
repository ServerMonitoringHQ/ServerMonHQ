class ContactMailer < ActionMailer::Base

  def support_email(email, sender_name, type, detail)    
    @email       = email
    @type        = type
    @sender_name = sender_name
    @detail      = detail
    mail(:from => email, :to => 'support@servermonitoringhq.com', :subject => 'ServerMonitoringHQ Support Email')   
  end
  
end
