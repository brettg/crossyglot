module Crossdress
  module Formats
    # The .puz file format. See http://code.google.com/p/puz/wiki/FileFormat for info
    class Puz < Puzzle
      MAGIC = "ACROSS&DOWN\0"
      # TOOD: Is this easy to infer somehow from HEADER_FORMAT?
      HEADER_LENGTH = 52
      # The parts of the header and there representation for String#unpack, IN ORDER!
      HEADER_PARTS = {file_cksum: 'v',
                      magic: 'a12',
                      header_cksum: 'v',
                      magic_cksum: 'Q<',
                      version: 'Z4',
                      junk1: 'v',
                      scrambled_cksum: 'v',
                      junk2: 'a12',
                      width: 'C',
                      height: 'C',
                      clue_count: 'v',
                      puzzle_type: 'v',
                      solution_state: 'v'}
      HEADER_FORMAT = HEADER_PARTS.values.join
      # Range of header parts used in header checksum
      HEADER_CKSUM_RANGE = -5..-1

      # defer given methods to the headers hash
      def self.defer_to_headers(*meth_names)
        meth_names.each do |meth_name|
          define_method(meth_name) do
            self.headers[meth_name]
          end
          define_method("#{meth_name}=") do |new_val|
            self.headers[meth_name] = new_val
          end
        end
      end

      defer_to_headers :version, :width, :height, :clue_count

      def headers
        @headers ||= {}
      end

      def parse(path)
        File.open(path,'rb:ASCII-8BIT') do |puzfile|
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

      private

      #---------------------------------------
      #   File Parsing
      #---------------------------------------

      def parse_header(puzfile)
        puzfile.gets(MAGIC)

        # Magic wasn't found, assume file is not good
        raise InvalidPuzzleError.new('invalid .puz file')  if puzfile.eof?

        # We want part of the header before the MAGIC, so go back a bit
        puzfile.pos -= MAGIC.size + 2

        header_values = puzfile.gets(HEADER_LENGTH).unpack(HEADER_FORMAT)
        HEADER_PARTS.keys.each_with_index do |name, idx|
          self.headers[name] = header_values[idx]
        end
      end

      def parse_solution(puzfile)
        solution = puzfile.gets(width * height)
        fill = puzfile.gets(width * height)

        count = 0
        x = 0
        y = 0

        cells.clear

        solution.each_char do |sol|
          cells << if ?. == sol
            Cell.black
          else
            above_cell = cell_at(x, y - 1)
            left_cell = cell_at(x - 1, y)

            across = !left_cell || left_cell.black?
            down = !above_cell || above_cell.black?
            number = (count += 1)  if across || down

            Cell.new(number, across, down, sol)
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
        clues.clear
        clue_count.times {clues << next_string(puzfile)}
      end

      # Next \0 delimited string from file, nil if of empty length
      def next_string(puzfile)
        s = puzfile.gets(?\0).chomp(?\0)
        s.empty? ? nil : s
      end

      #---------------------------------------
      #   Writing
      #---------------------------------------

      # def header_data
      # end

      def solution_data
        cells.map {|c| c.black? ? ?. : c.solution}.join
      end

      def fill_data
        cells.map {|c| c.fill || (c.black? ? ?. : ?-)}.join
      end

      #---------------------------------------
      #   Checksums
      #---------------------------------------

      def checksum(data, cksum=0)
        data.each_byte do |b|
          lowbit = cksum & 1
          cksum = cksum >> 1
          cksum += 0x8000  unless lowbit.zero?
          cksum = (cksum + b) & 0xffff
        end
        cksum
      end

      def header_cksum
        format = HEADER_FORMAT[HEADER_CKSUM_RANGE]
        values = HEADER_PARTS.keys[HEADER_CKSUM_RANGE].map{|k| headers[k]}

        checksum values.pack(format)
      end
    end
  end
end
