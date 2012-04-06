$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'crossyglot'
require 'fileutils'

include Crossyglot

module TestfileHelper
  TESTFILE_DIR = File.expand_path('../input-files', __FILE__)
  TMP_OUTPUT_DIR = File.expand_path('../tmp', __FILE__)

  # the full path to one of the test files in input-files
  def testfile_path(filename)
    File.expand_path(filename, TESTFILE_DIR)
  end

  # the full path for a file to be created in the tmp output dir
  # if a block is given the file will be deleted, if it exists after the block executes
  def tmp_output_path(filename)
    FileUtils.mkdir_p(TMP_OUTPUT_DIR)
    path = File.expand_path(filename, TMP_OUTPUT_DIR)

    if block_given?
      yield path
      FileUtils.rm_f(path)
    end

    path
  end
end

RSpec.configure do |c|
  include TestfileHelper
end
