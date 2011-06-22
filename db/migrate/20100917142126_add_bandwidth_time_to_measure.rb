class AddBandwidthTimeToMeasure < ActiveRecord::Migration
  def self.up
    add_column :measures, :bandwidth_time, :string
  end

  def self.down
    remove_column :measures, :bandwidth_time
  end
end
