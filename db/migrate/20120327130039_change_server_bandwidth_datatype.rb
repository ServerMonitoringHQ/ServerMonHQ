class ChangeServerBandwidthDatatype < ActiveRecord::Migration
  def up
    change_column :servers, :last_rx, :bigint
    change_column :servers, :last_tx, :bigint
  end

  def down
    change_column :servers, :last_rx, :integer
    change_column :servers, :last_tx, :integer
  end
end
