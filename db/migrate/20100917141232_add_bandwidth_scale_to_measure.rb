class AddBandwidthScaleToMeasure < ActiveRecord::Migration
  def self.up
    add_column :measures, :bandwidth_scale, :string
  end

  def self.down
    remove_column :measures, :bandwidth_scale
  end
end
