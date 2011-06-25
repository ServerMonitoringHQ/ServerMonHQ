class Keychain < ActiveRecord::Base
  
  require 'encryptor'
  require 'base64'
  require 'digest/sha1'

  JAKE_KEY = 'Jake Purton, 18/8/2006'

  belongs_to :server

  def after_initialize
    if self.private_key == nil 
      self.private_key = Base64.encode64(Encryptor.encrypt(:value =>
        generate_private_key, :key => JAKE_KEY))
    end
    if self.public_key == nil
      self.public_key = get_public_key(generate_private_key)
    end
    true
  end

  private

  def generate_private_key
    name = "#{Rails.root}/tmp/key_gen_#{Process.pid}#{rand(100)}"
    `ssh-keygen -t rsa -q -N '' -f #{name}`
    key = `cat #{name}`
    `rm #{name}`
    key
  end


  def get_public_key(private_key_pem)

    digest = Base64.encode64(SHA1.digest(private_key_pem)).gsub(/\n/, '')

    the_key = Rails.cache.fetch("#{digest}") do
      name = "#{Rails.root}/tmp/key_file_#{Process.pid}#{rand(100)}"
      File.open(name, 'w') do |file|
        file.puts(private_key_pem)
      end
      `chmod 600 #{name}`
      key = `ssh-keygen -y -f #{name}`
      key.gsub!(/\s/, '')
      key = key.insert(7, ' ')
    end
    return the_key + ' ServerPulse Key'
  end
end
