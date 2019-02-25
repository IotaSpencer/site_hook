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


desc "Run tests and setup"
tasks = %i[spec cucumber]
task default: tasks
desc 'run tests'
task tests: %i[spec cucumber]