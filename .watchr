def run_spec(file)
  unless File.exist?(file)
    puts "#{file} does not exist"
    return
  end

  puts "Running #{file}"
  system "bundle exec rspec --format documentation #{file}"
  puts
end

def run_all_specs
  puts "Running all specs"
  system "bundle exec rspec spec/"
  puts
end


watch("spec/.*_spec\.rb") do |match|
  run_spec match[0]
end

watch("lib/(.*)\.rb") do |match|
  run_spec %{spec/models/#{match[1]}_spec.rb}
end

watch("spec/(spec_helper|support/.*)\.rb$") do |match|
  run_all_specs
end


# Ctrl-\
Signal.trap 'QUIT' do
  puts
  run_all_specs
end
