class Keychain < ActiveRecord::Base
  
  require 'encryptor'
  require 'base64'
  require 'digest/sha1'

  belongs_to :server

  after_initialize :do_after_initialize

  def do_after_initialize
    if self.private_key == nil 
      k = SSHKey.generate
      self.private_key = Base64.encode64(Encryptor.encrypt(:value =>
        k.private_key, :key => SysStats::JAKE_PURTON))
      self.public_key = k.ssh_public_key 
    end
    true
  end

  def Keychain.random
    if (c = count) != 0
      find(:first, :offset =>rand(c))       
    end
  end

end
