class ConvertPasswordToText < ActiveRecord::Migration
  def self.up
    change_column :servers, :password, :text
  end

  def self.down
    change_column :servers, :password, :string
  end
end
