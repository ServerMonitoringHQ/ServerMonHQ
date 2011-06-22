# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'yaml'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  include AuthenticatedSystem

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'fe6b21ea888ac9a583035a54d971c48f'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  # Convert a hash to yml and send to resque
  def send_to_queue(queue, message)
    
    message[:timestamp] = Time.now.gmtime.to_s
    yml = YAML::dump(message)
    params = { :target => yml }
    x = Net::HTTP.post_form(URI.parse("http://pulse-resque.heroku.com/enqueue/#{queue}/"), 
      params) 

  end

  private

  def check_account_expired
    return unless current_user
    if current_user.account.expired?
      flash[:error] = 'Your Account has expired'
      redirect_to account_path
    end
  end

  def require_admin
    (authorized? && current_user.admin?) || access_denied
  end

end
