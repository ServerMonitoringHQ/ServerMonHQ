class DashboardController < ApplicationController

  def index
  
    @regs = Account.where('trial_end > ? and active = ?', Date.today, false).order('trial_end')
    @active = Account.where('active = ?', true).order('created_at')

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

end
