class CreateMonitorServers < ActiveRecord::Migration
  def self.up
    create_table :monitor_servers do |t|

      t.integer :server_id
      t.integer :measure_id

      t.timestamps
    end
  end

  def self.down
    drop_table :monitor_servers
  end
end
