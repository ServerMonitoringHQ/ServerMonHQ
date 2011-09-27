#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'rake/dsl_definition'

require File.expand_path('../config/application', __FILE__)

Servermonitoringhq::Application.load_tasks

namespace :resque do
  
  task :setup => :environment do
    unless defined?(ServerMonitoringHQ::Jobs::Logger)
  	 ServerMonitoringHQ::Jobs::Logger               = ActiveSupport::BufferedLogger.new("#{Rails.root}/log/resque.log")
  	 ServerMonitoringHQ::Jobs::Logger.auto_flushing = true
    end

    require 'systats'
  end

end

require 'resque/tasks'