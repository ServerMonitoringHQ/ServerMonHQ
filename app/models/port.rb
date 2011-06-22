class Port < ActiveRecord::Base
  belongs_to :server
  validates_presence_of :name, :address

  def status_text
    case status
      when -1
        return "Awaiting Data"
      when 0
        return "Down"
      else
        return "Up"
    end
  end

  def validate_on_create
    errors.add(:server_id, 'Port limit reached') if server.port_limit_reached?
  end
end
