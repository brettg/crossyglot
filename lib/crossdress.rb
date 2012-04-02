require 'crossdress/version'

module Crossdress
  class InvalidPuzzleError < StandardError
  end
end

require 'crossdress/cell'
require 'crossdress/puzzle'
Dir[File.expand_path('../crossdress/formats/*.rb', __FILE__)].each {|f| require f}
