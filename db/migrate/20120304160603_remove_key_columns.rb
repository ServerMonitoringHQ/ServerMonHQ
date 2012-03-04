class RemoveKeyColumns < ActiveRecord::Migration
  def up
    remove_column :servers, :private_key
    remove_column :servers, :public_key
  end

  def down
    add_column :servers, :private_key, :text
    add_column :servers, :public_key, :string
  end
end
