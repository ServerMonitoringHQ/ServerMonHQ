class AddPrivateKeyToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :private_key, :text
  end

  def self.down
    remove_column :servers, :private_key
  end
end
