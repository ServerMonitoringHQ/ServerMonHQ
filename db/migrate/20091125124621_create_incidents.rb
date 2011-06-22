class CreateIncidents < ActiveRecord::Migration
  def self.up
    create_table :incidents do |t|

      t.integer :server_id
      t.integer :measure_id
      t.integer :account_id
      t.integer :incident_type
      t.string :description
      t.boolean :open

      t.timestamps
    end
  end

  def self.down
    drop_table :incidents
  end
end