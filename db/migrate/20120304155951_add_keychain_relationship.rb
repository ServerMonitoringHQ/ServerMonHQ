class AddKeychainRelationship < ActiveRecord::Migration
  def up
    add_column :servers, :keychain_id, :integer
  end

  def down
    remove_column :servers, keychain_id
  end
end
