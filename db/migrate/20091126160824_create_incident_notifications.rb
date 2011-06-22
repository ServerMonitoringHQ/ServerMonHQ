class CreateIncidentNotifications < ActiveRecord::Migration
  def self.up
    create_table :incident_notifications do |t|

      t.integer :incident_id
      t.integer :user_monitor_id
      t.timestamps
    end
  end

  def self.down
    drop_table :incident_notifications
  end
end
