require 'test_helper'

class ServerTest < ActiveSupport::TestCase

  def test_should_create_server
    assert_difference 'Server.count' do
      server = create_server
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
