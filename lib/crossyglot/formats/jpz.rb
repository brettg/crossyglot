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

        @cword_elem = @xml.at('crossword')
        @grid_elem = @cword_elem.at('grid')

        parse_metadata
        parse_cells
        parse_clues

        self
      end

      private

      def parse_metadata
        self.title = @xml.at('title').text
        self.author = @xml.at('creator').text
        self.copyright = @xml.at('copyright').text

        self.height = @grid_elem['height'].to_i
        self.height = @grid_elem['width'].to_i
      end

      def parse_cells
        sorted_cells = @grid_elem.css('cell').sort_by{|ce| [ce['y'].to_i, ce['x'].to_i]}
        sorted_cells.each do |cell_elem|
          cells << if cell_elem['type'] == 'block'
            Cell.black
          else
            num = cell_elem['number']
            Cell.new(cell_elem['solution'], number: num && num.to_i)
          end
        end
      end

      def parse_clues
        cells_by_number =  cells.inject({}) {|accum, c| accum[c.number] = c if c.number; accum}
        @cword_elem.css('clues').each do |clues_elem|
          across = clues_elem.at('title').text[/across/i]

          clues_elem.css('clue').each do |clue_elem|
            cell = cells_by_number[clue_elem['number'].to_i]
            cell.send(across ? :across_clue= : :down_clue=, clue_elem.text)
          end
        end
      end

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
