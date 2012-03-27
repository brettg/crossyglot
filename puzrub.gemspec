# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'puzrub/version'

Gem::Specification.new do |s|
  s.name        = 'puzrub'
  s.version     = Puzrub::VERSION
  s.authors     = ['Brett Gibson']
  s.email       = ['gems@brettdgibson.com']
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = 'puzrub'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'watchr'
end
