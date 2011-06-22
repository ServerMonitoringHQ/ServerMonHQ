class IncidentsController < ApplicationController
  
  layout 'application'

  before_filter :login_required
  before_filter :check_account_expired

  # GET /incidents
  # GET /incidents.xml
  def index

    @incidents = current_user.account.incidents.paginate :page => params[:page], 
      :order => 'created_at DESC'

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @incidents }
    end
  end

  # GET /incidents/1
  # GET /incidents/1.xml
  def show
    @incident = current_user.account.incidents.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @measure }
    end
  end
end
