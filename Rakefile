require 'rdoc/task'
require 'bundler/gem_tasks'

desc 'Default: run specs.'
task :default => :spec

desc 'Run specs'
task :spec do
  exec 'rspec'
end

namespace :spec do
  if RUBY_PLATFORM[/darwin/i]
    namespace :puz do
      desc 'Use mdfind on OS X to find and run roundtrip test for all .puz files on system'
      task :roundtrip_all do
        cmd = 'mdfind -0 \'kMDItemKind = "Across Crossword"\' | sort -z | ' +
              'xargs -0 ./spec/bin/roundtrip'
        exec cmd
      end
    end
  end
end

desc 'Run the specs with watchr'
task :watch do
  exec 'watchr spec/spec.watchr'
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_dir = 'doc'
end


