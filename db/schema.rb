# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110215121510) do

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.date     "trial_end"
    t.boolean  "active",       :default => false
    t.integer  "package_type", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "plan_id",      :default => 0,     :null => false
  end

  create_table "disks", :force => true do |t|
    t.integer  "server_id"
    t.string   "path"
    t.string   "usedspace"
    t.string   "totalspace"
    t.string   "percent"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "histories", :force => true do |t|
    t.integer  "server_id"
    t.string   "name"
    t.integer  "slot"
    t.float    "mem_lo",                    :default => 0.0
    t.float    "mem_hi",                    :default => 0.0
    t.float    "mem_total",                 :default => 0.0
    t.integer  "mem_count",                 :default => 0
    t.float    "swap_lo",                   :default => 0.0
    t.float    "swap_hi",                   :default => 0.0
    t.float    "swap_total",                :default => 0.0
    t.integer  "swap_count",                :default => 0
    t.float    "cpu_lo",                    :default => 0.0
    t.float    "cpu_hi",                    :default => 0.0
    t.float    "cpu_total",                 :default => 0.0
    t.integer  "cpu_count",                 :default => 0
    t.integer  "bandwidth_tx", :limit => 8, :default => 0
    t.integer  "bandwidth_rx", :limit => 8, :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "down_mins",                 :default => 0
  end

  create_table "incident_notifications", :force => true do |t|
    t.integer  "incident_id"
    t.integer  "user_monitor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "incidents", :force => true do |t|
    t.integer  "server_id"
    t.integer  "measure_id"
    t.integer  "account_id"
    t.integer  "incident_type"
    t.string   "description"
    t.boolean  "open"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invites", :force => true do |t|
    t.string   "code"
    t.integer  "user_id"
    t.datetime "redeemed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "keychains", :force => true do |t|
    t.text "public_key"
    t.text "private_key"
  end

  create_table "logs", :force => true do |t|
    t.integer  "server_id"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "measures", :force => true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.integer  "mem_perc"
    t.integer  "load_perc"
    t.integer  "swap_perc"
    t.integer  "heartbeat"
    t.integer  "disk_perc"
    t.integer  "bandwidth"
    t.boolean  "notify_mem"
    t.boolean  "notify_load"
    t.boolean  "notify_swap"
    t.boolean  "notify_heartbeat"
    t.boolean  "notify_pages"
    t.boolean  "notify_ports"
    t.boolean  "notify_disk"
    t.boolean  "paused"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "bandwidth_scale"
    t.string   "bandwidth_time"
    t.boolean  "notify_bandwidth"
  end

  create_table "monitor_servers", :force => true do |t|
    t.integer  "server_id"
    t.integer  "measure_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "monitor_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "measure_id"
    t.integer  "wait_for"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", :force => true do |t|
    t.integer "server_id"
    t.integer "status",           :default => -1
    t.string  "title"
    t.string  "url"
    t.string  "search_text"
    t.boolean "follow_redirects"
    t.string  "last_error"
  end

  create_table "ports", :force => true do |t|
    t.integer  "server_id"
    t.integer  "status",     :default => -1
    t.string   "name"
    t.integer  "address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "servers", :force => true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.string   "url"
    t.string   "hostname"
    t.string   "username"
    t.text     "password",      :limit => 255
    t.string   "ssh_port"
    t.string   "access_key"
    t.text     "public_key",    :limit => 255
    t.text     "top"
    t.float    "cpuload"
    t.float    "load2"
    t.float    "load3"
    t.float    "usedmem"
    t.float    "totalmem"
    t.float    "usedswap"
    t.float    "totalswap"
    t.integer  "last_tx",       :limit => 8
    t.integer  "last_rx",       :limit => 8
    t.string   "platform"
    t.string   "distro"
    t.string   "kernelver"
    t.string   "mysql"
    t.string   "phpversion"
    t.string   "apacheversion"
    t.boolean  "serverdown"
    t.integer  "uptime",        :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cpucount",                     :default => 0,   :null => false
    t.float    "cpumhz",                       :default => 0.0, :null => false
    t.string   "cpu",                          :default => "",  :null => false
    t.text     "private_key"
    t.integer  "down_mins",                    :default => 0
  end

  create_table "users", :force => true do |t|
    t.integer  "account_id"
    t.string   "login",                     :limit => 40
    t.string   "first_name",                :limit => 100, :default => ""
    t.string   "last_name",                 :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "password_digest",           :limit => 40
    t.string   "salt",                      :limit => 40
    t.boolean  "admin",                                    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.string   "reset_code",                :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "mobile_number",             :limit => 20,  :default => "",    :null => false
    t.integer  "crm_id"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
