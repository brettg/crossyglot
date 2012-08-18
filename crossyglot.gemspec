# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'crossyglot/version'

Gem::Specification.new do |s|
  s.name        = 'crossyglot'
  s.version     = Crossyglot::VERSION
  s.authors     = ['Brett Gibson']
  s.email       = ['gems@brettdgibson.com']
  s.summary     = 'Library for reading and writing various crossword puzzle formats'
  s.description = 'Library for reading and writing various crossword puzzle formats'

  s.required_ruby_version = '>= 1.9'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']

  s.add_dependency 'nokogiri'
  s.add_dependency 'archive-zip'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'watchr'
end
