class CreateHistories < ActiveRecord::Migration
  def self.up
    create_table :histories do |t|
      
      t.integer :server_id
      t.string :name
      t.integer :slot

      t.float :mem_lo, :default => 0
      t.float :mem_hi, :default => 0
      t.float :mem_total, :default => 0
      t.integer :mem_count, :default => 0

      t.float :swap_lo, :default => 0
      t.float :swap_hi, :default => 0
      t.float :swap_total, :default => 0
      t.integer :swap_count, :default => 0

      t.float :cpu_lo, :default => 0
      t.float :cpu_hi, :default => 0
      t.float :cpu_total, :default => 0
      t.integer :cpu_count, :default => 0

      t.integer :bandwidth_tx, :default => 0, :limit => 8
      t.integer :bandwidth_rx, :default => 0, :limit => 8

      t.timestamps
    end
  end

  def self.down
    drop_table :histories
  end
end