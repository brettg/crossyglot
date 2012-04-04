require 'crossyglot/version'

module Crossyglot
  class InvalidPuzzleError < StandardError
  end
end

require 'crossyglot/cell'
require 'crossyglot/puzzle'
Dir[File.expand_path('../crossyglot/formats/*.rb', __FILE__)].each {|f| require f}
