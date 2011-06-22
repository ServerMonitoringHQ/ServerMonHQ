class AddPlanIdToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :plan_id, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :accounts, :plan_id
  end
end
