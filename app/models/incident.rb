class Incident < ActiveRecord::Base
  HIGH_MEMORY = 1
  HIGH_LOAD = 2
  SWAP_LIMT = 3
  SERVER_DOWN = 4
  DISK_LIMIT = 5
  PAGE_ERROR = 6
  PORT_ERROR = 7
  HIGH_BANDWIDTH = 8
  
  belongs_to :account
  belongs_to :server
  belongs_to :measure

  def type_to_text

    case incident_type
    when HIGH_LOAD
      return "High Load"
    when SWAP_LIMT
      return "High Swap"
    when SERVER_DOWN
      return "Server Down"
    when DISK_LIMIT
      return "Disk Limit"
    when PAGE_ERROR
      return "Page Error"
    when PORT_ERROR
      return "Port Error"
    when HIGH_BANDWIDTH
      return "High Bandwidth"
    when HIGH_MEMORY
      return "High Memory"
    else
      return "UNKNOWN"
    end

  end
end
