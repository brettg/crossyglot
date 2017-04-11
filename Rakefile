require 'rdoc/task'
require 'bundler/gem_tasks'

desc 'Default: run specs.'
task :default => :spec

desc 'Run specs'
task :spec do
  exec 'rspec'
end

desc 'Run the specs with watchr'
task :watch do
  exec 'watchr spec/spec.watchr'
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_dir = 'doc'
end
