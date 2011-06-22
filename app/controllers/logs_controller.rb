class LogsController < ApplicationController
 
  layout 'server' 
     
  before_filter :login_required
  before_filter :check_account_expired

  def index    
    @server = current_user.account.servers.find(params[:server_id])
    @title = 'Logfiles'     
    @logs = @server.logs.all
 
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @logs }
    end
  end
    
  def show
    @server = current_user.account.servers.find(params[:server_id])
    @log = @server.logs.find(params[:id])
    @title = 'Log : ' + @log.path
 
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @log }
    end
  end
 
  def new    
    @server = current_user.account.servers.find(params[:server_id])
    @log = Log.new
    @title = 'New Log'
 
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @log }
    end
  end
 
  def edit
    @server = current_user.account.servers.find(params[:server_id])    
    @log = Log.find(params[:id])
    @title = 'Edit Log'
  end
 
  def create    
    @server = current_user.account.servers.find(params[:server_id])
    @log = @server.logs.new(params[:log])
 
    respond_to do |format|
      if @log.save
        flash[:notice] = 'Log was successfully created.'
        format.html { redirect_to(server_logs_path(@server)) }
        format.xml  { render :xml => @log, :status => :created, :location => @log }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @log.errors, :status => :unprocessable_entity }
      end
    end
  end
 
  def update
    @server = current_user.account.servers.find(params[:server_id]) 
    @log = @server.logs.find(params[:id])
 
    respond_to do |format|
      if @log.update_attributes(params[:log])
        flash[:notice] = 'Log was successfully updated.'        
        format.html { redirect_to(server_logs_path(@server)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @log.errors, :status => :unprocessable_entity }
      end
    end
  end
 
  def destroy
    @server = current_user.account.servers.find(params[:server_id])
    @log = @server.logs.find(params[:id]);
    @log.destroy
 
    respond_to do |format|        
      format.html { redirect_to(server_logs_path(@server)) }
      format.xml  { head :ok }
    end
  end
end
