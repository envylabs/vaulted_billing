require 'rubygems'
require 'bundler/setup'
require 'appraisal'

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

namespace :ci do
  desc 'Run the tests on the CI server'
  task :run do
    exit_status = 1
    begin
      `bundle exec rspec --no-color spec/`.tap do |result|
        puts result
        exit_status = result =~ /\b0\s+failures?\b/ ? 0 : 1
      end
    ensure
      exit exit_status
    end
  end
end

task :default => :spec
