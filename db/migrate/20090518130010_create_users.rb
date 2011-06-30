class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true do |t|
      
      t.integer :account_id
      t.column :login,                     :string, :limit => 40
      t.column :first_name,                      :string, :limit => 100, :default => '', :null => true
      t.column :last_name,                      :string, :limit => 100, :default => '', :null => true
      t.column :email,                     :string, :limit => 100
      t.column :password_digest,           :string, :limit => 40
      t.column :admin,                     :boolean, :default => false
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string, :limit => 40
      t.column :reset_code,            :string, :limit => 40
      t.column :remember_token_expires_at, :datetime

    end
    add_index :users, :login, :unique => true
  end

  def self.down
    drop_table "users"
  end
end
