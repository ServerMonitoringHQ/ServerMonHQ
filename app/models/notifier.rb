class Notifier < ActionMailer::Base
  
 def alert_service_down(user_monitor, incidents)
   recipients user_monitor.user.email
   from       "noreply@serverpulsehq.com"
   subject    "Server Incident"
   body       ({:incidents => incidents, :user_monitor => user_monitor })
 end
  
 def alert_service_restored(user_monitor, incidents)
   recipients user_monitor.user.email
   from       "noreply@serverpulsehq.com"
   subject    "Server Incident - resolved"
   body       ({:incidents => incidents, :user_monitor => user_monitor })
 end
 
 def send_invitation(user, inviter, code)
   recipients user.email
   from       "noreply@serverpulsehq.com"
   subject    "You've been invited"
   body       ({:user => user, :inviter => inviter, :code => code })
 end
  
  def reset_notification(user)
    setup_email(user)
    @subject    += 'Link to reset your password'
    @body[:url]  = "http://serverpulsehq.com/reset/#{user.reset_code}"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "noreply@serverpulsehq.com"
      @subject     = "[ServerPulseHQ.com] "
      @sent_on     = Time.now
      @body[:user] = user
    end
 
end