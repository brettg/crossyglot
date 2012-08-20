$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'crossyglot'
require 'fileutils'

include Crossyglot

module TestfileHelper
  TESTFILE_DIR = File.expand_path('../puzzle-files', __FILE__)
  TMP_OUTPUT_DIR = File.expand_path('../tmp', __FILE__)

  # Returns the full path to one of the test files in puzzle-files/{puz-type}. You should be able to
  # include or omit puz-type as long as it matches the file extension.
  def testfile_path(filename)
    if filename.split('/').first != (ext = filename.split('.').last)
      filename = "#{ext}/#{filename}"
    end

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
    else
      path
    end
  end
end

module Roundtripper
  ROUNDTRIP_INVALID_FILE = '.roundtrip-invalids'
  ROUNDTRIP_INVALIDS = if File.exists?(ROUNDTRIP_INVALID_FILE)
    File.read(ROUNDTRIP_INVALID_FILE).split("\n").map!(&:strip)
  else
    []
  end

  def should_roundtrip_puz_file(path, ignore_known_invalids=false, save_output=false)
    File.open(path, 'rb:ASCII-8BIT') do |puzfile|
      puz = Formats::Puz.new.parse(puzfile, {strict: true})
      out = StringIO.open('', 'wb:ASCII-8BIT') {|sio| puz.write(sio); sio.string}
      out.force_encoding('BINARY')

      if save_output
        File.open(tmp_output_path(File.basename(path)), 'wb') {|out_f| out_f << out}
      end

      puzfile.rewind
      out.should == puzfile.read
    end
  rescue Crossyglot::InvalidPuzzleError => e
    if ignore_known_invalids && ROUNDTRIP_INVALIDS.include?(path)
      puts [RSpec.configuration.formatters.first.send(:yellow, "\tKnown Invalid:"), path,
            e.message].join(' ')
    else
      raise
    end
  end
end

RSpec.configure do |c|
  include TestfileHelper
  include Roundtripper
end
