require 'test_helper'

class ServerTest < ActiveSupport::TestCase

  def test_load_data_from_server
    
    record = Server.new({ :name => 'ServerPulse', :username => 'servermonhq', 
      :hostname => 'shell.ianpurton.com', :password => 'vja481x', 
      :ssh_port => 22, :cpu => 'Intel', :keychain_id => 1 })
    a = record.retrieve_stats(true)

    assert a == true, "Stats not retrieved::" + record.errors[:base][0].to_s
  end

  # To get this test to work you'll need to load the public key from the 
  # keychains fixtures file to a server. 
  # Run ‘tail -f /var/log/auth.log’ on the remotehost to help with debug. 
  def test_load_data_from_server_ssh
    
    record = Server.new({ :name => 'ServerPulse', :username => 'servermonhq', 
      :hostname => 'shell.ianpurton.com', 
      :ssh_port => 22, :cpu => 'Intel', :keychain_id => 1 })
    a = record.retrieve_stats(true)

    assert a == true, "Stats not retrieved::" + record.errors[:base][0].to_s
  end

  def test_decrypt_private_key

    kc = Keychain.find(1)

    record = Server.new({ :name => 'ServerPulse', :username => 'servermonhq', 
      :hostname => 'shell.ianpurton.com', 
      :ssh_port => 22, :cpu => 'Intel' })

    record.keychain_id = kc.id

    key_data = [Encryptor.decrypt(:value => Base64.decode64(record.keychain.private_key), 
      :key => SysStats::JAKE_PURTON)]

    puts key_data

  end

  def test_keychin_id_should_only_change_when_saved

    s = Server.new(:account_id => 6)
    key1 = s.keychain_id
    s = Server.new(:account_id => 6)
    key2 = s.keychain_id
    assert key1 == key2, "Keys should be the same"

  end


  def test_should_create_server
    assert_difference 'Server.count' do
      server = create_server
      assert !server.new_record?, "#{server.errors.full_messages.to_sentence}"
    end
  end

  def test_ok_with_no_password
    assert_difference 'Server.count' do
      server = create_server(:password => '')
      assert !server.new_record?, "#{server.errors.full_messages.to_sentence}"
    end
  end

protected
  def create_server(options = {})
    record = Server.new({ :name => 'ServerPulse', :username => 'ianpurton.com', 
      :hostname => 'terminal.ianpurton.com', :password => 'Vja481xian', 
      :ssh_port => 22, :cpu => 'Intel' }.merge(options))
    record.ssh true
    a = Account.new
    a.save
    record.account_id = a.id
    record.save
    record
  end
end
