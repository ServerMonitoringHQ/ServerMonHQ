require 'digest/sha1'

class User < ActiveRecord::Base
  # include Insight::CRM::Callbacks::User

  has_secure_password
  
  belongs_to :account

  validates_presence_of     :password, :on => :create 
  validates_presence_of     :login, :unless => Proc.new { |user| user.login.nil? }
  validates_length_of       :login, :within => 3..40, :unless => Proc.new { |user| user.login.nil? }
  validates_uniqueness_of   :login, :unless => Proc.new { |user| user.login.nil? }

  validates_length_of       :first_name,     :maximum => 100

  validates_length_of       :last_name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :mobile_number, :first_name, :last_name, :password, :password_confirmation



  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end
  
  def name
    first_name + ' ' + last_name
  end
  
  def create_reset_code
    @reset = true
    self.attributes = {:reset_code => Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )}
    save(false)
  end 
  
  def recently_reset?
    @reset
  end 

  def delete_reset_code
    self.attributes = {:reset_code => nil}
    save(false)
  end
end
