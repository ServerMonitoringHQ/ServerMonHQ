resque_config = YAML.load_file(File.dirname(__FILE__) + '/../resque.yml')

uri          = URI.parse(resque_config[Rails.env])
Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)