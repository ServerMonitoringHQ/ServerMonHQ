class StatisticsController < ApplicationController

  require 'net/http'
  require 'net/ssh'
  require 'uri'
  require "rexml/document"

  layout 'server', :except => [ :external, :stats, :dashboard ]
  
  before_filter :login_required, :except => [ :external, :stats, :dashboard ]
  before_filter :check_account_expired

  def index    
    
    @server = current_user.account.servers.find(params[:id])
 
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @server }
    end
  end

  def dashboard

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @server }
    end
  end
  
  def external

    @server = Server.by_access_key(params[:id]).first
 
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @server }
    end
  end
  
  def stats

    @server = Server.by_access_key(params[:id]).first

    xml = @server.stats_xml

    respond_to do |format|
      format.xml  { render :text => xml }
    end
  end 
       
  def top

    @server = current_user.account.servers.find(params[:id])
    xml = @server.top_xml

    respond_to do |format|
      format.xml  { render :text => xml }
    end
  end 
   
  def processes
    @server = current_user.account.servers.find(params[:id])
    
    @xml = @server.top_xml

    criteria = ['cpu_hi', 'cpu_lo']
    
    Time.zone = 'UTC'

    histories = @server.histories.all

    @data_vis_24hr = google_vis_data(histories, 24, criteria, 
      '24HR', Time.zone.now.hour, 1.hour, 'hour', '%a %H:%M')
    @data_vis_7days = google_vis_data(histories, 7, criteria, 
      'WEEK', Time.zone.now.wday, 1.day, 'wday', '%a %d')
    @data_vis_year = google_vis_data(histories, 12, criteria, 
      'MONTH', Time.zone.now.month, 28.days, 'month', '%b %Y')

    respond_to do |format|      
      format.html # processes.html.erb
    end
    
  end  

  def downtime
    @server = current_user.account.servers.find(params[:id])
    
    histories = @server.histories.where('down_mins IS NOT ?', nil)

    @total_24hr_down = histories.select { |v| v.name == '24HR' }.inject(0) { 
      |sum, v| sum + v.down_mins unless v.down_mins == nil }
    @total_1week_down = histories.select { |v| v.name == 'WEEK' }.inject(0) { 
      |sum, v| sum + v.down_mins unless v.down_mins == nil }
    @total_1year_down = histories.select { |v| v.name == 'MONTH' }.inject(0) { 
      |sum, v| sum + v.down_mins unless v.down_mins == nil }

    Time.zone = 'UTC'

    criteria = ['down_mins']

    @data_vis_24hr = google_vis_data(histories, 24, criteria, 
      '24HR', Time.zone.now.hour, 1.hour, 'hour', '%a %H:%M')
    @data_vis_7days = google_vis_data(histories, 7, criteria, 
      'WEEK', Time.zone.now.wday, 1.day, 'wday', '%a %d')
    @data_vis_year = google_vis_data(histories, 12, criteria, 
      'MONTH', Time.zone.now.month, 28.days, 'month', '%b %Y')
    
  end
   
  def bandwidth
    @server = current_user.account.servers.find(params[:id])
    
    Time.zone = 'UTC'

    histories = @server.histories.all
    @total_24hr_tx = histories.select { |v| v.name == '24HR' }.inject(0) { |sum, v| sum + v.bandwidth_tx }
    @total_24hr_rx = histories.select { |v| v.name == '24HR' }.inject(0) { |sum, v| sum + v.bandwidth_rx }
    @total_1week_tx = histories.select { |v| v.name == 'WEEK' }.inject(0) { |sum, v| sum + v.bandwidth_tx }
    @total_1week_rx = histories.select { |v| v.name == 'WEEK' }.inject(0) { |sum, v| sum + v.bandwidth_rx }
    @total_1year_tx = histories.select { |v| v.name == 'MONTH' }.inject(0) { |sum, v| sum + v.bandwidth_tx }
    @total_1year_rx = histories.select { |v| v.name == 'MONTH' }.inject(0) { |sum, v| sum + v.bandwidth_rx }
    
    criteria = ['bandwidth_tx', 'bandwidth_rx']

    @data_vis_24hr = google_vis_data(histories, 24, criteria, 
      '24HR', Time.zone.now.hour, 1.hour, 'hour', '%a %H:%M')
    @data_vis_7days = google_vis_data(histories, 7, criteria, 
      'WEEK', Time.zone.now.wday, 1.day, 'wday', '%a %d')
    @data_vis_year = google_vis_data(histories, 12, criteria, 
      'MONTH', Time.zone.now.month, 28.days, 'month', '%b %Y')
    
  end

  def google_vis_data(histories, slots, criteria, name, slot_now, 
    time_scale, time_method, time_format)

    Time.zone = 'UTC'
    timer = Time.zone.now
    histories = histories.find_all{ |hist| hist.name == name }
    data_vis = ''
    (slots - 1).downto(0) do |index|
      hist_slot = histories.select{ |hist| hist.slot == eval('timer.' + time_method)}
      if hist_slot[0] != nil
        data_vis += "data.setValue(#{index}, 0, '#{timer.strftime(time_format)}');"
        criteria.each_index do |i|
          val = eval('hist_slot[0].' + criteria[i] + '.to_s')
          val = '0' if val == ''
          data_vis += "data.setValue(#{index}, #{i + 1}, #{val});"
        end
      else
        data_vis += "data.setValue(#{index}, 0, '#{timer.strftime(time_format)}');"
        criteria.each_index do |i|
          data_vis += "data.setValue(#{index}, #{i + 1}, 0);"
        end
      end
      timer = timer - time_scale
    end

    return data_vis
  end
  
  def memory
    @server = current_user.account.servers.find(params[:id])
    
    criteria = ['mem_lo', 'mem_hi']
     
    Time.zone = 'UTC'

    histories = @server.histories.all

    @data_vis_24hr = google_vis_data(histories, 24, criteria, 
      '24HR', Time.zone.now.hour, 1.hour, 'hour', '%a %H:%M')
    @data_vis_7days = google_vis_data(histories, 7, criteria, 
      'WEEK', Time.zone.now.wday, 1.day, 'wday', '%a %d')
    @data_vis_year = google_vis_data(histories, 12, criteria, 
      'MONTH', Time.zone.now.month, 28.days, 'month', '%b %Y')
  end 
  
  def meminfo

    @server = current_user.account.servers.find(params[:id])
    xml = @server.memory_xml

    respond_to do |format|
      format.xml  { render :text => xml }
    end
  end 

end
