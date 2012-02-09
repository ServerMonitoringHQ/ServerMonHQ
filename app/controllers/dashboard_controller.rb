class DashboardController < ApplicationController

  def index
  
    @regs = Account.where('created_at > ?', 7.days.ago)
    @servers = Server.where('created_at > ?', 7.days.ago)
    @recv = Server.where('updated_at > ? and uptime is not null', 7.days.ago)
    @total = Server.active.count

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

end
