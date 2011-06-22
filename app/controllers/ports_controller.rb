class PortsController < ApplicationController
  
  before_filter :login_required
  before_filter :check_account_expired

  layout 'server'
  
  # GET /ports
  # GET /ports.xml
  def index    
    
    @server = current_user.account.servers.find(params[:server_id])
    
    @ports = @server.ports.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @ports }
    end
  end

  # GET /ports/1
  # GET /ports/1.xml
  def show
    
    @server = current_user.account.servers.find(params[:server_id])
    @port = @server.ports.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @port }
    end
  end

  # GET /ports/new
  # GET /ports/new.xml
  def new
    @server = current_user.account.servers.find(params[:server_id])
    @port = Port.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @port }
    end
  end

  # GET /ports/1/edit
  def edit
    @title = 'Edit Port'
    @server = current_user.account.servers.find(params[:server_id])
    @port = @server.ports.find(params[:id])
  end

  # POST /ports
  # POST /ports.xml
  def create
    @server = current_user.account.servers.find(params[:server_id])
    @port = @server.ports.new(params[:port])

    respond_to do |format|
      if @port.save
        flash[:notice] = 'Port was successfully created.'
        format.html { redirect_to(server_ports_path(@server)) }
        format.xml  { render :xml => @port, :status => :created, :location => @port }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @port.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ports/1
  # PUT /ports/1.xml
  def update
    @server = current_user.account.servers.find(params[:server_id])
    @port = @server.ports.find(params[:id])

    respond_to do |format|
      if @port.update_attributes(params[:port])
        flash[:notice] = 'Port was successfully updated.'
        format.html { redirect_to(server_ports_path(@server)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @port.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ports/1
  # DELETE /ports/1.xml
  def destroy
    @server = current_user.account.servers.find(params[:server_id])
    @port = Port.find(params[:id])
    @port.destroy

    respond_to do |format|
      format.html { redirect_to(server_ports_path(@server)) }
      format.xml  { head :ok }
    end
  end
end
