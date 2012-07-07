require 'nokogiri'
require 'zip/zip'
module Crossyglot
  module Formats
    class Jpz < Puzzle
      # Parses a puzzle from the IO object given.
      #
      # @param [String, IO] path_or_io The path on disk of the puzzle or a subclass of IO containing
      #                                the puzzle data
      # @options [Hash] options Options Does nothing for this class
      # @returns self
      def parse_file(path, options={})
        File.open(path) do |puzfile|
          parse_io(puzfile, options)
        end
      end

      # Parses a puzzle from the IO object given
      #
      # @param [IO] puzfile A subclass of IO with the puzzle data
      # @options [Hash] options See #parse_file options
      # @returns self
      def parse_io(puzfile, options={})
        # puzfile = unzip_if_zip(puzfile)
        @xml = Nokogiri::XML(puzfile.read) {|config| config.noblanks}
        @xml.remove_namespaces!
        @xml = @xml.at('rectangular-puzzle')

        self.title = @xml.at('title').text

        self
      end

      private

      # def unzip_if_zip(io)
      #   begin
      #     # Using the rubyzip API funkily so we get a ZipError if the file magic doesn't match
      #     (zip_entry = Zip::ZipEntry.new).read_local_entry(io)
      #     zip_entry.get_input_stream
      #   rescue Zip::ZipError
      #     # Assume we're dealing with an IO full of XML
      #     io
      #   end
      # end

    end
  end
end
