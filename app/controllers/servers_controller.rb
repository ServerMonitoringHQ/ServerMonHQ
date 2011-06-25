class ServersController < ApplicationController

  before_filter :login_required
  before_filter :check_account_expired
  config.filter_parameters :password, :private_key

  protect_from_forgery :except => [:history]
  
  layout 'application', :except => [ 'rename', 'remove' ]

  # GET /servers
  # GET /servers.xml
  def index
    @servers = current_user.account.servers.includes(:ports, :pages)

    respond_to do |format|
      format.html # index.html.erb
      format.js { render(:partial => 'server_list', :locals => {:servers => @servers}) }
      format.xml  { render :xml => @servers }
    end
  end
     
  def rename
    @server = current_user.account.servers.find(params[:id])
  end
  
  def remove
    @server = current_user.account.servers.find(params[:id])
  end
  
  def renamed
    @server = current_user.account.servers.find(params[:id])
    
    @server.name = params[:server][:name]
    @server.save
    
    respond_to do |format|
      format.html { redirect_to(servers_url) }
      format.xml  { head :ok }
    end
  end
  
  def removed
    @server = current_user.account.servers.find(params[:id])
    @server.destroy
    
    respond_to do |format|
      format.html { redirect_to(servers_url) }
      format.xml  { head :ok }
    end
  end
   
  def configure    
    @server = current_user.account.servers.find(params[:id])
  end
  
  def download
    send_file Rails.root + '/public/phpscript/stats.php', 
    :filename => params[:id] + '.php' 
  end

  # GET /servers/1
  # GET /servers/1.xml
  def show
    @server = current_user.account.servers.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @server }
    end
  end

  # GET /servers/new
  # GET /servers/new.xml
  def new
    @server = current_user.account.servers.new
    @measures = current_user.account.measures
    @server.ssh_port = 22
    @checked = true

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @server }
    end
  end

  def newagent
    @server = current_user.account.servers.new
    @measures = current_user.account.measures
    @server.ssh_port = 22
    @checked = true

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @server }
    end
  end

  # GET /servers/1/edit
  def agentedit
    @server = current_user.account.servers.find(params[:id])
    @server.password = ''

    respond_to do |format|
      format.html # edit.html.haml
      format.xml  { render :xml => @server }
    end
  end

  # GET /servers/1/edit
  def edit
    @server = current_user.account.servers.find(params[:id])
    @server.password = ''

    respond_to do |format|
      format.html # edit.html.haml
      format.xml  { render :xml => @server }
    end
  end

  # POST /servers
  # POST /servers.xml
  def create

    @server = current_user.account.servers.new(params[:server])
    @measures = current_user.account.measures
    @monitor_server = MonitorServer.new(params[:monitor_server])
    @checked = false 
    if params[:measure]
      @checked = true
    end

    # Handle both agents and ssh connections
    action = :newagent
    if params[:ssh]
      @server.ssh(true)
      action = :new
    end

    respond_to do |format|
      if @server.valid? and @server.retrieve_stats and @server.save

        if @checked
          @monitor_server.server_id = @server.id
          @monitor_server.save
          monitor_user = MonitorUser.new
          monitor_user.measure_id = @monitor_server.measure_id
          monitor_user.user_id = current_user.id
          monitor_user.wait_for = 5
          monitor_user.wait_for = 30 if current_user.account.plan_id = 0
          monitor_user.save
        end

        flash[:notice] = 'Server was successfully created.'
        format.html { redirect_to(:controller => :statistics, :id => @server.id) }
        format.xml  { render :xml => @server, :status => :created, :location => @server }
      else
        format.html { render :action => action }
        format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /servers/1
  # PUT /servers/1.xml
  def update
    @server = current_user.account.servers.find(params[:id])

    if params[:server][:password] == ''
      params[:server].delete(:password)
    end

    # Handle both agents and ssh connections
    action = :agentedit
    if params[:ssh]
      @server.ssh(true)
      action = :edit
    end
    
    update = @server.update_attributes(params[:server])

    respond_to do |format|
      if update and @server.retrieve_stats(true)
        flash[:notice] = 'Server was successfully updated.'
        format.html { redirect_to(:controller => :statistics, :id => @server.id) }
        format.xml  { head :ok }
      else
        @server.password = ''
        format.html { render :action => action }
        format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /servers/1
  # DELETE /servers/1.xml
  def destroy
    @server = current_user.account.servers.find(params[:id])
    @server.destroy

    respond_to do |format|
      format.html { redirect_to(servers_url) }
      format.xml  { head :ok }
    end
  end

  def may_add
    @limit_reached = current_user.account.limit_reached?
  end

end
