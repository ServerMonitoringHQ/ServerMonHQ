class AddNotifyBandwidthToMeasure < ActiveRecord::Migration
  def self.up
    add_column :measures, :notify_bandwidth, :boolean
  end

  def self.down
    remove_column :measures, :notify_bandwidth
  end
end
