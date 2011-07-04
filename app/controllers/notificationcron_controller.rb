class NotificationcronController < ApplicationController

  def notification_cron

    MonitorUser.active.each do |um|
      process_new_incidents(um)
      process_resolved_incidents(um)
    end

    render :layout => false
  end

  private 

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
      NotificationMailer.alert_service_restored(um, resolved_incidents).deliver
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
      NotificationMailer.alert_service_down(um, new_incidents).deliver
    end
  end

end
