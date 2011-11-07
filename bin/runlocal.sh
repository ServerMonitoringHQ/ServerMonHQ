export RAILS_ENV=production
export QUEUE=servermonitoringhq
bundle exec rake resque:work 
