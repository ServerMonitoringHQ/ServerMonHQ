class CreateDisks < ActiveRecord::Migration
  def self.up
    create_table :disks do |t|
      t.integer :server_id
      t.string :path
      t.string :usedspace
      t.string :totalspace
      t.string :percent

      t.timestamps
    end
  end

  def self.down
    drop_table :disks
  end
end
