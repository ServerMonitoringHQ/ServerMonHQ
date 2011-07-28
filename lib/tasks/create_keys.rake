desc "Pre-create all the secret ssh keys"
task :create_ssh_keys => :environment do
  puts "Creating keys"
  10.times do 
    k = Keychain.new
    k.save
  end
end
