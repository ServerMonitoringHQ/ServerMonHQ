class AddLastErrorToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :last_error, :string
  end

  def self.down
    remove_column :pages, :last_error
  end
end
