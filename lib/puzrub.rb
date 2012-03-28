require 'puzrub/version'

module Puzrub
  class InvalidPuzzleError < StandardError
  end
end

require 'puzrub/cell'
require 'puzrub/puzzle'
Dir[File.expand_path('../puzrub/formats/*.rb', __FILE__)].each {|f| require f}
