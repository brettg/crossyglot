require 'nokogiri'
require 'archive/zip'

module Crossyglot
  module Formats
    class Jpz < Puzzle
      PRIMARY_NAMESPACE = 'http://crossword.info/xml/crossword-compiler'
      PUZZLE_NAMESPACE = 'http://crossword.info/xml/rectangular-puzzle'

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
        unzip_if_zip(puzfile) do |unzipped_puzfile|
          @xml = Nokogiri::XML(unzipped_puzfile.read) {|config| config.noblanks}
          @xml.remove_namespaces!
          @xml = @xml.at('rectangular-puzzle')

          @cword_elem = @xml.at('crossword')
          @grid_elem = @cword_elem.at('grid')

          parse_metadata
          parse_cells
          parse_clues
        end

        self
      end

      # Write xml of this puzzle to given IO object
      #
      # @param [IO] io
      def write_io(io)
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.send('crossword-compiler-applet', xmlns: PRIMARY_NAMESPACE) do
            xml.send('rectangular-puzzle', xmlns: PUZZLE_NAMESPACE) do
              xml.metadata do
                xml.creator author
                xml.title title
                xml.copyright copyright
                xml.description description  if description
              end

              xml.grid(height: height, width: width) do
                write_cells(xml)
              end
            end
          end
        end

        io.write(builder.to_xml)
      end

      # Write xml of this puzzle to file at path
      #
      # @param [String] path
      def write_file(path)
        File.open(path, 'w') {|f| write_io(f)}
      end

      private

      def parse_metadata
        self.title = @xml.at('title').text
        self.author = @xml.at('creator').text
        self.copyright = @xml.at('copyright').text

        self.height = @grid_elem['height'].to_i
        self.width = @grid_elem['width'].to_i
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

      def write_cells(xml)
        each_cell do |cell, x, y|
          cell_attrs = {x: x, y: y}
          if cell.black?
            cell_attrs[:type] = 'block'
          else
            cell_attrs[:solution] = cell.solution
            cell_attrs[:number] = cell.number  if cell.number
          end

          xml.cell cell_attrs
        end
      end

      def unzip_if_zip(io)
        Archive::Zip.new(io).each do |z_file|
          yield z_file.file_data  if z_file.file?
          break
        end
      rescue Archive::Zip::UnzipError
        io.rewind
        yield io
      end

    end
  end
end
