class AddKeychains < ActiveRecord::Migration
  def self.up
    create_table :keychains do |t|
      t.text :public_key
      t.text :private_key
    end
  end

  def self.down
    drop_table :keychains
  end
end
