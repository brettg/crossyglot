module Puzrub
  module Formats
    class Puz
      MAGIC = "ACROSS&DOWN\0"
      HEADER_LENGTH = 38
      HEADER_FORMAT = 'vVVZ4vva12CCvvv'

      class << self
        def parse(path, puzzle)

          File.open(path, 'rb:ASCII-8BIT') do |puzfile|
            puzfile.gets(MAGIC)

            # Magic wasn't found
            raise InvalidPuzzleError.new('invalid .puz file')  if puzfile.eof?

            headers = puzfile.gets(HEADER_LENGTH)
            headers = headers.unpack(HEADER_FORMAT)

            version = headers[3]
            width = headers[7]
            height = headers[8]
            clue_count = headers[9]

            solution = puzfile.gets(width * height)
            solved = puzfile.gets(width * height)

            parse_string_sections(puzzle, puzfile)
          end
        end


        # def write(puzzle)
        # end

        private

        def parse_string_sections(puzzle, puzfile)
          puzzle.title = next_string(puzfile)
          puzzle.author = next_string(puzfile)
          puzzle.copyright = next_string(puzfile)
        end

        def parse_clues(puzzle, puzfile)
        end

        def next_string(puzfile)
          puzfile.gets("\0").chomp("\0")
        end
      end

    end
  end
end
