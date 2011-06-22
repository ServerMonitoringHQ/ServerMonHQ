class DashboardController < ApplicationController

  def index
  
    regs = Account.where('created_at > ?', Date.today).count
    servers = Server.where('created_at > ?', Date.today).count
    recv = Server.where('updated_at > ? and uptime is not null', Date.today).count
    total = Server.active.count

    render :text => "Signups Today - #{regs}, Servers Commisioned - #{servers}" +
      ", Servers Updated #{recv}/#{total}"
  end

end
