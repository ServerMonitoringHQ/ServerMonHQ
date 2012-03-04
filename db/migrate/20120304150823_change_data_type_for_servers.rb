class ChangeDataTypeForServers < ActiveRecord::Migration
  def up
    change_column :servers, :last_tx, :bigint
    change_column :servers, :last_rx, :bigint
    change_column :servers, :uptime, :bigint
    change_column :histories, :bandwidth_tx, :bigint
    change_column :histories, :bandwidth_rx, :bigint
  end

  def down
    change_column :servers, :last_tx, :integer
    change_column :servers, :last_rx, :integer
    change_column :servers, :uptime, :integer
    change_column :histories, :bandwidth_tx, :integer
    change_column :histories, :bandwidth_rx, :integer
  end
end
