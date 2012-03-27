class MeasuresController < ApplicationController
  
  layout 'application'
 
  skip_before_filter :verify_authenticity_token, :only => [:add_user, :add_server]    
  before_filter :login_required
  before_filter :check_account_expired

  # GET /measures
  # GET /measures.xml
  def index
    @measures = current_user.account.measures.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @measures }
    end
  end

  # GET /measures/1
  # GET /measures/1.xml
  def show
    @measure = current_user.account.measures.find(params[:id])

    @users = current_user.account.users

    @servers = current_user.account.servers

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @measure }
    end
  end

  # GET /measures/new
  # GET /measures/new.xml
  def new
    @measure = Measure.new
    @measure.set_defaults

    @load_options = load_dropdown

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @measure }
    end
  end

  # GET /measures/1/edit
  def edit
    @load_options = load_dropdown
    @measure = current_user.account.measures.find(params[:id])
  end

  def load_dropdown
    ar = []
    0.step(400,10) { |i|
      ar << [i.to_s + '%', i]
    }
    return ar
  end

  # POST /measures
  # POST /measures.xml
  def create
    @measure = current_user.account.measures.new(params[:measure])

    respond_to do |format|
      if @measure.save
        flash[:notice] = 'Measure was successfully created.'
        format.html { redirect_to(@measure) }
        format.xml  { render :xml => @measure, :status => :created, :location => @measure }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @measure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /measures/1
  # PUT /measures/1.xml
  def update
    @measure = current_user.account.measures.find(params[:id])

    respond_to do |format|
      if @measure.update_attributes(params[:measure])
        flash[:notice] = 'Measure was successfully updated.'
        format.html { redirect_to(@measure) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @measure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /measures/1
  # DELETE /measures/1.xml
  def destroy
    @measure = current_user.account.measures.find(params[:id])
    @measure.destroy

    respond_to do |format|
      format.html { redirect_to(measures_url) }
      format.xml  { head :ok }
    end
  end

  def remove_server
    @measure = current_user.account.measures.find(params[:measure_id])
    ms = @measure.monitor_servers.find(params[:id])
    ms.destroy

    respond_to do |format|
      format.html { redirect_to(measure_url(@measure)) }
      format.xml  { head :ok }
    end
  end

  def remove_user
    @measure = current_user.account.measures.find(params[:measure_id])
    mu = @measure.monitor_users.find(params[:id])
    mu.destroy

    respond_to do |format|
      format.html { redirect_to(measure_url(@measure)) }
      format.xml  { head :ok }
    end
  end

  def add_user
    @measure = current_user.account.measures.find(params[:measure_id])

    mu = MonitorUser.new
    mu.measure_id = @measure.id
    mu.wait_for = params[:wait_for].to_i 
    mu.notify_type = params[:notify_type].to_i
    mu.user_id = params[:user_id].to_i
    mu.save

    respond_to do |format|
      format.xml  { render :xml => mu.to_xml }
    end
  end

  def add_server
    @measure = current_user.account.measures.find(params[:measure_id])

    mu = MonitorServer.new
    mu.measure_id = @measure.id
    mu.server_id = params[:server_id].to_i
    mu.save

    respond_to do |format|
      format.xml  { render :xml => mu.to_xml }
    end
  end
end
