class CreateMonitorUsers < ActiveRecord::Migration
  def self.up
    create_table :monitor_users do |t|

      t.integer :user_id
      t.integer :measure_id
      t.integer :wait_for

      t.timestamps
    end
  end

  def self.down
    drop_table :monitor_users
  end
end
