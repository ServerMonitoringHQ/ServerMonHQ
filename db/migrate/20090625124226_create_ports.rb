class CreatePorts < ActiveRecord::Migration
  def self.up
    create_table :ports do |t|      
      
      t.integer :server_id
      t.integer :status, :default => -1 
      t.string :name
      t.integer :address

      t.timestamps
    end
  end

  def self.down
    drop_table :ports
  end
end