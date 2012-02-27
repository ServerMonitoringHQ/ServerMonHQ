source 'http://rubygems.org'

gem 'rails', '3.1.0'

# Asset template engines
group :assets do
  gem 'sass'
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

gem "exception_notification",         
  :git => "git://github.com/rails/exception_notification.git",
  :require => "exception_notifier"

gem 'jquery-rails'
gem 'haml'
gem 'sprockets'

gem 'execjs'
gem 'therubyracer'
gem 'net-ssh'

gem 'encryptor'
gem 'hominid'
gem 'kaminari'
gem 'twilio'
gem 'resque'

group :development do
  gem 'sqlite3'
end

group :production do 
  gem 'therubyracer-heroku', '0.8.1.pre3' # you will need this too   
  gem 'pg' 
  gem 'thin'
end

group :test do
  # Pretty printed test output
  # gem 'turn', :require => false
  gem 'assert_valid_markup'
end
