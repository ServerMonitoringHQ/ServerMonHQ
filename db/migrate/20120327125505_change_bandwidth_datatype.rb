class ChangeBandwidthDatatype < ActiveRecord::Migration
  def up
    change_column :histories, :bandwidth_rx, :bigint
    change_column :histories, :bandwidth_tx, :bigint
  end

  def down
    change_column :histories, :bandwidth_rx, :integer
    change_column :histories, :bandwidth_tx, :integer
  end
end
