class AccountsController < ApplicationController
  
  layout 'application'

  before_filter :require_admin
  before_filter :load_account, :only => [:show, :create]

  def show
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @incidents }
    end
  end

  private

  def load_account
    @account = current_user.account
  end
end
