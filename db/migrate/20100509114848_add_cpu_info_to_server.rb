class AddCpuInfoToServer < ActiveRecord::Migration
  def self.up
    add_column :servers, :cpucount, :integer, :null => false, :default => 0
    add_column :servers, :cpumhz,   :float,   :null => false, :default => 0
    add_column :servers, :cpu,      :string,  :null => false, :default => '', :length => 50
  end

  def self.down
    remove_column :servers, :cpu
    remove_column :servers, :cpucount
    remove_column :servers, :cpumhz
  end
end
