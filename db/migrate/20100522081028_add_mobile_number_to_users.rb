class AddMobileNumberToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :mobile_number, :string, :null => false, :default => '', :limit => 20
  end

  def self.down
    remove_column :users, :mobile_number
  end
end
