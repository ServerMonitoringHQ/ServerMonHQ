class CreateMeasures < ActiveRecord::Migration
  def self.up
    create_table :measures do |t|
      
      t.integer :account_id
      t.string :name
      t.integer :mem_perc
      t.integer :load_perc
      t.integer :swap_perc
      t.integer :heartbeat
      t.integer :disk_perc
      t.integer :bandwidth
      t.boolean :notify_mem
      t.boolean :notify_load
      t.boolean :notify_swap
      t.boolean :notify_heartbeat
      t.boolean :notify_pages
      t.boolean :notify_ports
      t.boolean :notify_disk
      t.boolean :paused

      t.timestamps
    end
  end

  def self.down
    drop_table :measures
  end
end
