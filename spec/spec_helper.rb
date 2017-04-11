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
    path = File.expand_path(File.basename(filename), TMP_OUTPUT_DIR)

    if block_given?
      FileUtils.mkdir_p(TMP_OUTPUT_DIR)
      yield path
      FileUtils.rm_f(path)
    else
      path
    end
  end
end

module SamePuzzle
  class Matcher
    def initialize(expected)
      @expected = expected
    end

    def matches?(actual)
      @actual = actual

      attributes_same? && cells_same?
    end

    def failure_message
      [attributes_msg, cells_msg].compact.join("\n")
    end

    private

    def attributes_msg
      "Mismatched puzzle attributes:\n" + mismatched_attrs_msg  unless @mismatched_attrs.empty?
    end
    def cells_msg
      # Never got to cell check because of mismatched attributes. Just stop.
      if defined?(@cell_length_correct)
        if @cell_length_correct
          "Mismatched cells:" +
          @mismatched_cells.map { |(idx, m_attrs)| "\n\t#{idx} - #{m_attrs.join(', ')}" }
        else
          "Cell array length does not match. Expected #{@expected.cells.size}, " +
          "got #{@actual.cells.size}"
        end
      end
    end

    def mismatched_attrs_msg
      @mismatched_attrs.map do |a|
        exp = @expected.public_send(a)
        act = @actual.public_send(a)
        "\t#{a} – Expected: #{exp.inspect} Got: #{act.inspect}\n"  if !exp.eql?(act)
      end.compact.join
    end

    def attributes_same?
      unless defined?(@mismatched_attrs)
        @mismatched_attrs = %i{
          author copyright notes title description
          height width
          timer_at
          timer_running? diagramless?
        }.select do |attr|
          !@expected.public_send(attr).eql?(@actual.public_send(attr))
        end
      end

      @mismatched_attrs.empty?
    end

    def cells_same?
      unless defined?(@cell_length_correct)
        @cell_length_correct = (@expected.cells.size == @actual.cells.size)
        if @cell_length_correct
          @mismatched_cells = @expected.cells.zip(@actual.cells).map.with_index do |(c1, c2), idx|
            m_attrs = %i{number solution fill
                         across_clue down_clue
                         down_length across_length
                         is_incorrect is_black is_circled
                         was_previously_incorrect was_revealed}.select do |attr|
                           c1.public_send(attr) != c2.public_send(attr)
                         end
            [idx, m_attrs] unless m_attrs.empty?
          end.compact
        else
          @mismatched_cells = []
        end
      end

      @cell_length_correct && @mismatched_cells.empty?
    end
  end

  def be_same_puzzle(expected)
    SamePuzzle::Matcher.new(expected)
  end
end

module PuzRoundTripper
  ROUNDTRIP_INVALID_FILE = File.expand_path('~/.crossyglot/roundtrip-invalids')
  ROUNDTRIP_INVALIDS = if File.exists?(ROUNDTRIP_INVALID_FILE)
    File.read(ROUNDTRIP_INVALID_FILE).split("\n").map!(&:strip)
  else
    []
  end

  class Matcher
    attr_reader :expected, :actual

    # For PuzRTCLI
    def self.file_ext; "puz" end

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
    PuzRoundTripper::Matcher.new
  end
end

module JpzSanityCheck
  class Matcher
    # For PuzRTCLI
    def self.file_ext; "jpz"; end

    def matches?(path)
      @path = path

      @expected = Formats::Jpz.new.parse(@path)
      sio = StringIO.new('a.jpz', 'w+')
      @expected.write(sio)
      sio.rewind
      @actual = Formats::Jpz.new.parse(sio)

      @sp_matcher = SamePuzzle::Matcher.new(@expected)
      @sp_matcher.matches?(@actual)
    rescue Crossyglot::Formats::Jpz::NoRootJpzNode
      # Should only happen in case of invalid zip or XML, ignore for now...
      true
    end

    def failure_message
      "JPZ Sanity Check Failed:\n" + @sp_matcher.failure_message
    end
  end

  def pass_sanity_check(expected_path)
    JpzSanityCheck::Matcher.new(expected_path)
  end
end

RSpec.configure do |config|
  include TestfileHelper
  include PuzRoundTripper
  include SamePuzzle

  config.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }
end
