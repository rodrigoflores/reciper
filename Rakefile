require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--order rand -f d"
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
end

task :default => :spec