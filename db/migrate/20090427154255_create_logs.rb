class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
      
      t.integer :server_id
      t.string :path
      
      t.timestamps
    end
  end

  def self.down
    drop_table :logs
  end
end
