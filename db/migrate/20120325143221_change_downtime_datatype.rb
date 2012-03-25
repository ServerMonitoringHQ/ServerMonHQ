class ChangeDowntimeDatatype < ActiveRecord::Migration
  def up
    change_column :histories, :down_mins, :bigint
  end

  def down
    change_column :histories, :down_mins, :integer
  end
end
