require 'rubygems'
require 'bundler'
Bundler.setup

task :spec do
  system "rspec -cfs spec"
end

task :gem do
  system "bundle exec gem build artifice.gemspec"
end

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
