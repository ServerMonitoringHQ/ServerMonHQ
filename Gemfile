source 'http://rubygems.org'

gem 'rails', '3.1.0.rc4'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

# Asset template engines
gem 'sass-rails', "~> 3.1.0.rc"
gem 'coffee-script'
gem 'uglifier'

gem 'sprockets', :git => 'git://github.com/sstephenson/sprockets.git', :tag => 'v2.0.0.beta.10'

gem 'jquery-rails'
gem 'execjs'
gem 'therubyracer'
gem 'haml'
gem 'net-ssh'

gem 'encryptor'
gem 'hominid'
gem 'kaminari'
gem 'twilio'
gem 'resque'

gem "insight_rails", "0.3.1", :require => "insight"

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
  gem 'turn', :require => false
  gem 'assert_valid_markup'
end
