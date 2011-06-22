class MarketingController < ApplicationController
  
  layout 'marketing'

  def index
    @remember_me = true
  end 
  
  def privacy
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
