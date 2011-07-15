require 'test_helper'

class ServerTest < ActiveSupport::TestCase

  def test_load_data_from_server
    record = Server.new({ :name => 'ServerPulse', :username => 'ianpurton.com', :hostname => 'terminal.ianpurton.com', :password => 'Vja481xian', :ssh_port => 22, :cpu => 'Intel' })

    record.retrieve_stats
  end

  def test_password_gets_encrypted

    s = Server.new(:account_id => 6)

    key = Keychain.find(1).private_key

    assert (s.send :decode_private_key) == key, 'Should decode private key'

  end

  def test_private_key_should_only_change_when_saved

    s = Server.new(:account_id => 6)
    key1 = s.private_key
    s = Server.new(:account_id => 6)
    key2 = s.private_key
    assert key1 == key2, "Keys should be the same"

  end

  def test_public_key_creation
    s = Server.new(:account_id => 6)
    key1 = s.private_key

    assert_not_nil s.public_key

    server = create_server(options = {:private_key => key1})
    id = server.id

    s = Server.find(id)
    stored_key = s.private_key
    assert key1 == stored_key, "They should be the same"
  end

#  def test_should_not_create_server_if_not_logging_in
#    server = create_server(:password => '')
#    assert !server.retrieve_stats
#  end

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
    record = Server.new({ :name => 'ServerPulse', :username => 'ianpurton.com', :hostname => 'terminal.ianpurton.com', :password => 'Vja481xian', :ssh_port => 22, :cpu => 'Intel' }.merge(options))
    record.ssh true
    a = Account.new
    a.save
    record.account_id = a.id
    record.save
    record
  end
end
