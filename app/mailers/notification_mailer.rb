class NotificationMailer < ActionMailer::Base

  default from: "servermonitoringhq.com"

  def alert_service_down(user_monitor, incidents)
    @incidents = incidents
    @user_monitor = user_monitor

    mail(:to => user_monitor.user.email, :subject => "Server Incident")
  end
   
  def alert_service_restored(user_monitor, incidents)
    @incidents = incidents
    @user_monitor = user_monitor

    mail(:to => user_monitor.user.email, :subject => "Server Incident - Resolved")
  end
  
  def send_invitation(user, inviter, code)
    @user = user
    @inviter = inviter
    @code = code

    mail(:to => user.email, :subject => "You've been invited.")
  end
  
  def reset_notification(user)
    @url  = "http://servermonitoringhq.com/reset/#{user.reset_code}"
    @user = user
    @sent_on     = Time.now

    mail(:to => user.email, :subject => 
      "[ServerMonitoringHQ.com] Link to reset your password")
  end
end
