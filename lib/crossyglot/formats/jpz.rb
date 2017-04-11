require 'nokogiri'
require 'archive/zip'

module Crossyglot
  module Formats
    class Jpz < Puzzle
      class NoRootJpzNode < InvalidPuzzleError; end;

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
          @xml = Nokogiri::XML(unzipped_puzfile.read) { |c| c.noblanks }
          @xml.remove_namespaces!
          @xml = @xml.at('rectangular-puzzle')

          raise NoRootJpzNode.new("Invalid .jpz XML, no root node found")  unless @xml

          if @xml
            @cword_elem = @xml.at('crossword')
            @grid_elem = @cword_elem.at('grid')

            parse_metadata
            parse_cells
            parse_clues
          end
        end

        update_word_lengths!

        self
      end

      # Write xml of this puzzle to given IO object
      #
      # @param [IO] io
      def write_io(io)
        update_word_lengths!

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.send('crossword-compiler-applet', xmlns: PRIMARY_NAMESPACE) do
            xml.send('rectangular-puzzle', xmlns: PUZZLE_NAMESPACE) do
              xml.metadata do
                xml.creator author  if author
                xml.title title  if title
                xml.copyright copyright  if copyright
                xml.description description  if description
              end

              xml.crossword do
                xml.grid(height: height, width: width) do
                  write_cells(xml)
                end

                write_words(xml)
                write_clues(xml)
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

      def text_at(elem, root=@xml)
        @xml.at(elem) && @xml.at(elem).text
      end

      def parse_metadata
        self.title = text_at('metadata title')
        self.author = text_at('metadata creator')
        self.copyright = text_at('metadata copyright')

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
        cells_by_number =  cells.inject({}) { |accum, c| accum[c.number] = c if c.number; accum }
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
          cell_attrs = {x: x + 1, y: y + 1}
          if cell.black?
            cell_attrs[:type] = 'block'
          else
            cell_attrs[:solution] = cell.solution
            cell_attrs[:number] = cell.number  if cell.number
          end

          xml.cell cell_attrs
        end
      end

      def write_words(xml)
        id = 1
        each_cell do |cell, x, y|
          if cell.across?
            xml.word(id: id, x: [x + 1, x + cell.across_length].join('-'), y: y + 1)
            id += 1
          end
        end
        each_cell do |cell, x, y|
          if cell.down?
            xml.word(id: id, x: x + 1, y: [y + 1, y + cell.down_length].join('-'))
            id += 1
          end
        end
      end

      def write_clues(xml)
        word_id = write_clue_set(xml, 'Across', acrosses)
        write_clue_set(xml, 'Down', downs, word_id)
      end

      def write_clue_set(xml, title, clues, word_id=1)
        xml.clues(ordering: 'normal') do
          xml.title title
          clues.each do |(n, clue)|
            xml.clue clue, number: n, word: word_id
            word_id += 1
          end
        end
        word_id
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

  Puzzle::FORMAT_EXTENSIONS['jpz'] = Formats::Jpz
end
