require File.dirname(__FILE__) + '/../systats.rb'

desc "Pre-create all the secret ssh keys"
task :create_ssh_keys => :environment do
  puts "Creating keys"
  1000.times do 
    k = Keychain.new
    k.save
    puts '.'
  end
end
