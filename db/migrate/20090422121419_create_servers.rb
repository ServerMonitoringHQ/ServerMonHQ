class CreateServers < ActiveRecord::Migration
  def self.up
    create_table :servers do |t|
      t.integer :account_id
      t.string :name
      t.string :url
      t.string :hostname
      t.string :username
      t.string :password
      t.string :ssh_port
      t.string :access_key
      t.string :public_key
      t.text :top
      t.float :cpuload
      t.float :load2
      t.float :load3
      t.float :usedmem
      t.float :totalmem
      t.float :usedswap
      t.float :totalswap
      t.integer :last_tx, :limit => 8
      t.integer :last_rx, :limit => 8
      t.string :platform
      t.string :distro
      t.string :kernelver
      t.string :mysql
      t.string :phpversion
      t.string :apacheversion
      t.boolean :serverdown
      t.integer :uptime, :limit => 8

      t.timestamps
    end
  end

  def self.down
    drop_table :servers
  end
end
