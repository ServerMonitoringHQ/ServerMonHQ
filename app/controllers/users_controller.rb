class UsersController < ApplicationController
  layout 'application', :except => :reset
  layout 'session', :only => :reset
 
  before_filter :login_required, :except => [:forgot, :reset, :create, :new]
  before_filter :check_account_expired

  def index    
    @users = current_user.account.users.where('login IS NOT NULL')
      
    @people = current_user.account.users.where('login IS NULL')
 
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end
 
  # render add.rhtml
  def add
    @user = User.new
  end
 
  def add_user
    @user = current_user.account.users.new(params[:user])
    @user.password = 'just_filler'
    @user.password_confirmation = 'just_filler'
    
    respond_to do |format|
      if @user.save
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to(users_path) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => 'add' }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
 
  def edit
    @user = current_user.account.users.find(params[:id])
    @user.password = ''
  end
  
  def update    
    @user = current_user.account.users.find(params[:id])
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'        
        format.html { redirect_to(users_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @log.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # render invite.rhtml
  def invite
    @user = current_user.account.users.find(params[:id])
  end  
  
  def send_invite
    @user = current_user.account.users.find(params[:id])
    
    invite = Invite.create(:user_id => @user.id)
    
    NotificationMailer.send_invitation(@user, current_user, invite.code).deliver
    
    flash[:notice] = "Invite successfully sent"
    
    redirect_to(users_path)
  end
  
  def invitation
    @invite = Invite.find_by_code(params[:id])
    @user = User.find(@invite.user_id)
    render :layout => 'marketing'
  end
  
  def accept_invitation
    @invite = Invite.find_by_code(params[:id])
    @user = User.find(@invite.user_id)
    
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'        
        format.html { redirect_to(login_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "invitation" }
        format.xml  { render :xml => @log.errors, :status => :unprocessable_entity }
      end
    end
      
  end

  def new
    @account = Account.new

    if params[:plan_id] != nil
      @account.plan_id = params[:plan_id].to_i
    end

    @user = User.new
    render :layout => "marketing"
  end
 
  def create    
    @user = User.new(params[:user])
    @user.mobile_number = ''
    @account = Account.new(params[:account])
    @account.trial_end = 14.days.from_now

    # For a free trial account un-comment below
    #@account.active = true if @account.plan_id == 0

    success =  @account && @account.save
    @user.account_id = @account.id
    @user.admin = true
    success = @user && @user.save && success

    if success && @user.errors.empty? && @account.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      session[:user_id] = @user.id
     
      begin
        # Save out to Fat Free
        #l = Api::Lead.new({ :first_name => @user.first_name, :last_name => @user.last_name, 
        #  :email => @user.email, :user_id => 1})
        #l.save
        
        # Add now to mailchimp
        #h = Hominid::Base.new({:api_key => '72c8ca6a7ea19fcb9dabf68ff38e360b-us1'})
        #h.subscribe(h.find_list_id_by_name("ServerMonitoringHQ Signups"), @user.email, 
        #  {:FNAME => @user.first_name, :LNAME => @user.last_name}, {:email_type => 'html'})
      rescue
        # Do nothing
      end

      # Add a default monitor
      measure = current_user.account.measures.new(:name => 'Default Monitor')
      measure.set_defaults
      measure.save

      redirect_to(new_server_url)
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => :new, :layout => 'marketing'
    end
  end
  
  def destroy    
    @user = current_user.account.users.find(params[:id])
    @user.destroy
    
    respond_to do |format|        
      format.html { redirect_to(users_path) }
      format.xml  { head :ok }
    end
  end
  
  def forgot
    if request.post?
      user = User.find_by_email(params[:user][:email])
      if user
        user.create_reset_code

        NotificationMailer.reset_notification(user).deliver
        flash[:notice] = "Reset code sent to #{user.email}"
      else
        flash[:notice] = "#{params[:user][:email]} does not exist in system"
      end
      redirect_back_or_default('/')
    else
      render :layout => 'session'
    end
  end
  
  def reset
    @user = User.find_by_reset_code(params[:reset_code]) unless params[:reset_code].nil?
    if request.post?
      if @user.update_attributes(:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
        self.current_user = @user
        @user.delete_reset_code
        flash[:notice] = "Password reset successfully for #{@user.email}"
        redirect_back_or_default('/')
      else
        render :action => :reset
      end
    end
  end

  def show
    @user = current_user.account.users.find(params[:id])
  end

end
