class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|      
      t.integer :server_id
      t.integer :status, :default => -1 
      t.string :title
      t.string :url
      t.string :search_text
      t.boolean :follow_redirects
    end
  end

  def self.down
    drop_table :pages
  end
end