$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'puzrub'

include Puzrub

TESTFILE_DIR = File.expand_path('../input-files', __FILE__)
