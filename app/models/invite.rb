require 'digest/sha1'

class Invite < ActiveRecord::Base
  
  # Callbacks
  before_create :generate_code
  
  # Named Scope
  scope :redeemed, :conditions => ["redeemed_at IS NOT NULL"]
  
  scope :unredeemed, :conditions => ["redeemed_at IS NULL"]
  
  def redeem!
    self.redeemed_at = Time.now
    self.save!
  end
  
  def redeemed?
    !redeemed_at.nil?
  end
  
  protected
  
    def generate_code
      self.code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
  
end
