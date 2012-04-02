class NotificationcronController < ApplicationController

  def notification_cron

    MonitorUser.active.each do |um|
      process_new_incidents(um)
      process_resolved_incidents(um)
    end

    render :layout => false
  end

  private 

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
          msg += "\n#{resolved_incidents.description}"
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
          msg += "\n#{new_incidents.description}"
        }
        send_text(um.user.mobile_number, msg)
      end
    end
  end

end
