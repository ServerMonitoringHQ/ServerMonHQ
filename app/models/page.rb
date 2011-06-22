class Page < ActiveRecord::Base
  
  belongs_to :server
  validates_presence_of :url, :title
  
  def status_text
    case status
      when -1
        return "Awaiting Data"
      when 0
        return "Down " + last_error
      else
        return "Up"
    end
  end
  
  def validate
  begin
    uri = URI.parse(url)
    if uri.class != URI::HTTP
      errors.add(:url, 'Only HTTP protocol addresses can be used')
    end
    rescue URI::InvalidURIError
      errors.add(:url, 'The format of the url is not valid.')
    end
  end
  
  def validate_on_create
    errors.add(:server_id, 'Page limit reached') if server.page_limit_reached?
  end
end
