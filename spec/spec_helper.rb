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

module RoundTripper
  ROUNDTRIP_INVALID_FILE = File.expand_path('~/.crossyglot/roundtrip-invalids')
  ROUNDTRIP_INVALIDS = if File.exists?(ROUNDTRIP_INVALID_FILE)
    File.read(ROUNDTRIP_INVALID_FILE).split("\n").map!(&:strip)
  else
    []
  end

  class Matcher
    attr_reader :expected, :actual

    def matches?(puz_path)
      @path = puz_path

      File.open(@path, 'rb:ASCII-8BIT') do |puzfile|
        puz = Formats::Puz.new.parse(puzfile, {strict: true})

        sio = StringIO.new(''.b, 'wb')
        puz.write(sio)
        @actual = sio.string

        puzfile.rewind
        @expected = puzfile.read
      end

      !mismatch_offset
    end

    def failure_message
      "Roundtrip mismatch at offset: #{mismatch_offset}\nExpected:\n" +
      color_puzzle(@expected, 33)  +
      "\nActual:\n" +
      color_puzzle(@actual)
    end

    def mismatch_offset
      unless defined?(@_mismatch_offset)
        @_mismatch_offset ||= (0...@expected.size).detect { |n| @actual[n] != @expected[n] }
      end

      @_mismatch_offset
    end

    def color_puzzle(puzzle, mismatch_color=31)
      o = mismatch_offset
      puzzle[0..o].inspect[1..-2] + color(puzzle[(o + 1)..-1].inspect[1..-2], mismatch_color)
    end

    def color(text, color_code)
      "\e[#{color_code}m#{text}\e[0m"
    end

  end

  def roundtrip_successfully
    RoundTripper::Matcher.new
  end
end

RSpec.configure do |config|
  include TestfileHelper
  include RoundTripper

  config.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }
end
