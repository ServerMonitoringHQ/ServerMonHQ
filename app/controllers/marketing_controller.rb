class MarketingController < ApplicationController
  
  layout 'marketing'

  def index
    @remember_me = true
    @mixpanel.track_event("Acquisition")
  end 
  
  def privacy
  end

  def contact
    @success = params[:success]
  end
  
  def terms
  end
  
  def agent
  end
  
  def tour
  end
  
  def buy
    @account = Account.new
    @user = User.new
  end

end
