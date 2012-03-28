module Puzrub
  module Formats
    # The .puz file format. See http://code.google.com/p/puz/wiki/FileFormat for info
    class Puz < Puzzle
      MAGIC = "ACROSS&DOWN\0"
      HEADER_LENGTH = 38
      HEADER_FORMAT = 'vVVZ4vva12CCvvv'

      attr_accessor :version

      def parse(path)
        File.open(path, 'rb:ASCII-8BIT') do |puzfile|
          parse_magic(puzfile)
          parse_header(puzfile)

          parse_solution(puzfile)

          parse_string_sections(puzfile)
          parse_clues(puzfile)

          self.notes = next_string(puzfile)
        end

        self
      end

      # def write(path)
      # end


      def cksum_region(data, cksum=0)
        data.each_byte do |b|
          lowbit = cksum & 1
          cksum = cksum >> 1
          cksum += 0x8000  unless lowbit.zero?
          cksum = (cksum + b) & 0xffff
        end
        cksum
      end

      private

      def parse_magic(puzfile)
        puzfile.gets(MAGIC)

        # Magic wasn't found
        raise InvalidPuzzleError.new('invalid .puz file')  if puzfile.eof?
      end

      def parse_header(puzfile)
        headers = puzfile.gets(HEADER_LENGTH)
        headers = headers.unpack(HEADER_FORMAT)

        self.version = headers[3]
        self.width = headers[7]
        self.height = headers[8]
        self.clue_count = headers[9]
      end

      def parse_solution(puzfile)
        solution = puzfile.gets(width * height)
        solved = puzfile.gets(width * height)

        count = 1
        x = 0
        y = 0

        self.cells = []
        solution.each_char do |c|
          self.cells << cell = Cell.new
          if c == ?.
            cell.is_black = true
          else
            cell.solution = c

            above = cell_at(x, y - 1)
            left = cell_at(x - 1, y)

            if !above || above.black?
              cell.down_number = count
            end

            if !left || left.black?
              cell.across_number = count
            end

            if cell.down_number || cell.across_number
              count += 1
            end
          end

          x += 1
          if x == width
            x = 0
            y += 1
          end
        end
      end

      def parse_string_sections(puzfile)
        self.title = next_string(puzfile)
        self.author = next_string(puzfile)
        self.copyright = next_string(puzfile)
      end

      def parse_clues(puzfile)
        self.clues = []
        clue_count.times {self.clues << next_string(puzfile)}
      end

      # Next \0 delimited string from file, nil if of empty length
      def next_string(puzfile)
        s = puzfile.gets(?\0).chomp(?\0)
        s.empty? ? nil : s
      end

    end
  end
end
