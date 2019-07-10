require "bundler/gem_tasks"
require 'rake/testtask'

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:cucumber, 'cucumber features')
rescue LoadError
  # Don't worry about empty rescue
end


begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/**/*_spec.rb'
  end
rescue LoadError
  # Don't worry about empty rescue
end

require 'rake'
require 'bundler'
Bundler.setup
require 'grape-route-helpers'
require 'grape-route-helpers/tasks'
require 'grape-raketasks'
require 'grape-raketasks/tasks'

desc 'load the Rake environment.'
task :environment do
  require File.expand_path('lib/site_hook/env/env.rb', File.dirname(__FILE__))
end

desc "Run tests and setup"
tasks = %i[spec cucumber]
task default: tasks
desc 'run tests'
task tests: %i[spec cucumber]