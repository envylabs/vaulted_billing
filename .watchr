ENV['WATCHR'] = '1'

system 'clear'

def growl(message)
  message = message.gsub(/\e\[(\d+)m/, '').split("\n").detect { |l| l =~ /\d+ examples?, \d+ failures?/ } # strip bash color codes
puts message.inspect
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
  `#{cmd}`
end

def run_spec(file)
  system 'clear'

  unless File.exist?(file)
    puts "#{file} does not exist"
    return
  end

  puts "Running #{file}"
  result = run "bundle exec rspec --format documentation #{file}"
  growl result rescue nil
  puts result
end

def run_all_specs
  system 'clear'
  puts "Running all specs"
  result = run "bundle exec rspec spec/"
  growl result rescue nil
  puts result
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
