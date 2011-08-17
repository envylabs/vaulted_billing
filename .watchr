ENV['WATCHR'] = '1'

require 'open4'

system 'clear'

def growl(message)
  message = message.gsub(/\e\[(\d+)m/, '').split("\n").detect { |l| l =~ /\d+ examples?, \d+ failures?/ } # strip bash color codes
  growlnotify = `which growlnotify`.chomp
  title = "Watchr Test Results"
  passed = message =~ /\b0 failure/
  image = passed ? "~/.watchr/images/passed.png" : "~/.watchr/images/failed.png"
  severity = passed ? 'Very Low' : 'Emergency'
  options = "-w -n Watchr --image '#{File.expand_path(image)}' -m '#{message}' '#{title}' -p '#{severity}'"
  system %(#{growlnotify} #{options} &)
end

def run(cmd)
  puts cmd
  Open4::popen4(cmd) do |pid, stdin, stdout, stderr|
    while line = stdout.gets
      $stdout.write line
      growl line if line =~ /\b\d+ failure/
    end
  end
end

def run_spec(file)
  system 'clear'

  unless File.exist?(file)
    puts "#{file} does not exist"
    return
  end

  puts "Running #{file}"
  run "bundle exec rspec --format documentation #{file}"
end

def run_all_specs
  system 'clear'
  puts "Running all specs"
  run "bundle exec rspec --format documentation spec/"
end


watch("spec/.*_spec\.rb") do |match|
  run_spec match[0]
end

watch("lib/(.*)\.rb") do |match|
  run_spec %{spec/models/#{match[1]}_spec.rb}
end

watch("lib/vaulted_billing/gateways/(.+)\.rb") do |match|
  run_spec %{spec/requests/#{match[1]}_spec.rb}
end

watch("spec/(spec_helper|support/.*)\.rb$") do |match|
  run_all_specs
end


# Ctrl-\
Signal.trap 'QUIT' do
  puts
  run_all_specs
end
