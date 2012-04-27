# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Servermonitoringhq::Application.initialize!

Servermonitoringhq::Application.config.middleware.use "Mixpanel::Tracker::Middleware", "ab2192d8724107fdd4037f5f1ec30803"
