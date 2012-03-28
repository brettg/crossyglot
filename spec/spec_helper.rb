$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'puzrub'

include Puzrub


module TestfileHelper
  TESTFILE_DIR = File.expand_path('../input-files', __FILE__)
  def testfile_path(filename)
    File.expand_path(filename, TESTFILE_DIR)
  end
end

RSpec.configure do |c|
  include TestfileHelper
end
