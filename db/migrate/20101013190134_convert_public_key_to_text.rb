class ConvertPublicKeyToText < ActiveRecord::Migration
  def self.up
    change_column :servers, :public_key, :text
  end

  def self.down
    change_column :servers, :public_key, :string
  end
end
