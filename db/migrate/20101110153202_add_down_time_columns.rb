class AddDownTimeColumns < ActiveRecord::Migration
  def self.up
    add_column :servers, :down_mins, :integer, :default => 0
    add_column :histories, :down_mins, :integer, :default => 0
  end

  def self.down
    remove_column :servers, :down_mins
    remove_column :histories, :down_mins
  end
end
