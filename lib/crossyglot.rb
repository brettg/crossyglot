require 'crossyglot/version'

module Crossyglot
  class Error < StandardError; end
  class InvalidPuzzleError < Error; end
  class InvalidPuzzleFormat < Error; end
  class InvalidExtensionError < Error; end
end

require 'crossyglot/cell'
require 'crossyglot/puzzle'
Dir[File.expand_path('../crossyglot/formats/*.rb', __FILE__)].each {|f| require f}
