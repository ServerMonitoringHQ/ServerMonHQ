class PagesController < ApplicationController
  
  before_filter :login_required
  before_filter :check_account_expired

  layout 'server'
  
  def index    
    
    @server = current_user.account.servers.find(params[:server_id])
    
    @title = 'Page Monitoring'
    
    @pages = @server.pages.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pages }
    end
  end
 
  # GET /pages/1
  # GET /pages/1.xml
  def show
    
    @server = current_user.account.servers.find(params[:server_id])
    @page = @server.pages.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @page }
    end
  end
  # GET /pages/new
  # GET /pages/new.xml
  def new
    @server = current_user.account.servers.find(params[:server_id])
    @page = Page.new
    
    @title = 'New Page'
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @page }
    end
  end
  # GET /pages/1/edit
  def edit
    @title = 'Edit Page'
    @server = current_user.account.servers.find(params[:server_id])
    @page = @server.pages.find(params[:id])
  end
  # POST /pages
  # POST /pages.xml
  def create
    @server = current_user.account.servers.find(params[:server_id])
    @page = @server.pages.new(params[:page])
    respond_to do |format|
      if @page.save
        flash[:notice] = 'Page was successfully created.'
        format.html { redirect_to(server_pages_path(@server)) }
        format.xml  { render :xml => @page, :status => :created, :location => @page }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end
  # PUT /pages/1
  # PUT /pages/1.xml
  def update
    @server = current_user.account.servers.find(params[:server_id])
    @page = @server.pages.find(params[:id])
    respond_to do |format|
      if @page.update_attributes(params[:page])
        flash[:notice] = 'Page was successfully updated.'
        format.html { redirect_to(server_pages_path(@server)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end
  # DELETE /pages/1
  # DELETE /pages/1.xml
  def destroy
    @server = current_user.account.servers.find(params[:server_id])
    @page = @server.pages.find(params[:id])
    @page.destroy
    respond_to do |format|
      format.html { redirect_to(server_pages_path(@server)) }
      format.xml  { head :ok }
    end
  end
end
