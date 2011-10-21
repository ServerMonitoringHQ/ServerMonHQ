class ContactsController < ApplicationController
  
  layout 'marketing'
  
  def show
    @contact = Contact.new(:id => 1)

    respond_to do |format|
      format.html
    end
  end
  
  def create
    @contact = Contact.new(params[:contact])     
    if @contact.save
      flash.now[:notice] = "Support was successfully sent."
      render :action => 'show'
    else       
      flash[:alert] = "You must fill all fields."       
      render :action => 'show'     
    end
  end
  
end