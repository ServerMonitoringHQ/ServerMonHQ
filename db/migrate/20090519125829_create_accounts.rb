class CreateAccounts < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      
      t.string :name
      t.date :trial_end
      t.boolean :active, :default => false
      t.integer :package_type, :default => 0
      t.timestamps
      
    end
  end

  def self.down
    drop_table :accounts
  end
end