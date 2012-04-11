module Crossyglot
  module Formats
    # The .puz file format. See http://code.google.com/p/puz/wiki/FileFormat for info
    class Puz < Puzzle
      MAGIC = "ACROSS&DOWN\0"
      ICHEATED_MASK = 'ICHEATED'.unpack('C*')
      # TOOD: Is this easy to infer somehow from HEADER_FORMAT?
      HEADER_LENGTH = 52
      # The parts of the header and there representation for String#unpack, IN ORDER!
      HEADER_PARTS = {puzzle_cksum: 'v',
                      magic: 'a12',
                      header_cksum: 'v',
                      icheated_cksum: 'a8',
                      version: 'Z4',
                      unknown1: 'v',
                      scrambled_cksum: 'v',
                      unknown2: 'a12',
                      width: 'C',
                      height: 'C',
                      clue_count: 'v',
                      puzzle_type: 'v',
                      solution_state: 'v'}
      HEADER_DEFAULTS = {magic: MAGIC, version: '1.3', puzzle_type: 1}
      HEADER_FORMAT = HEADER_PARTS.values.join
      # Range of header parts used in header checksum
      HEADER_CKSUM_RANGE = -5..-1

      # defer given methods to the headers hash
      def self.proxy_to_headers(*meth_names)
        meth_names.each do |meth_name|
          define_method(meth_name) do
            self.headers[meth_name]
          end
          define_method("#{meth_name}=") do |new_val|
            self.headers[meth_name] = new_val
          end
        end
      end

      ##
      # :method: version
      proxy_to_headers :version, :width, :height

      def headers
        @headers ||= HEADER_DEFAULTS.clone
      end

      def parse(path_or_io)
        if path_or_io.is_a?(String)
          File.open(path_or_io,'rb:ASCII-8BIT') do |puzfile|
            parse_io(puzfile)
          end
        else
          parse_io(path_or_io)
        end

        self
      end

      # Write out the file. If given a path the file will be created (unless it exists), if given an
      # IO the puz data will be written to the IO.
      def write(path_or_io)
        if path_or_io.is_a? String
          File.open(path_or_io, 'wb') do |f|
            write_to_io(f)
          end
        else
          write_to_io(path_or_io)
        end
      end

      private

      #---------------------------------------
      #   File Parsing
      #---------------------------------------

      def parse_io(puzfile)
        parse_header(puzfile)

        parse_solution(puzfile)

        parse_string_sections(puzfile)
        parse_clues(puzfile)

        self.notes = next_string(puzfile)
      end

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

        solution.each_char.with_index do |sol, idx|
          cells << if ?. == sol
            Cell.black
          else
            above_cell = cell_at(x, y - 1)
            left_cell = cell_at(x - 1, y)

            across = !left_cell || left_cell.black?
            down = !above_cell || above_cell.black?
            number = (count += 1)  if across || down
            c_fill = fill[idx] == ?- ? nil : fill[idx]

            Cell.new(number, across, down, sol, c_fill)
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
        headers[:clue_count].times {clues << next_string(puzfile)}
      end

      # Next \0 delimited string from file, nil if of empty length
      def next_string(puzfile)
        s = puzfile.gets(?\0).chomp(?\0)
        s.empty? ? nil : s
      end

      #---------------------------------------
      #   Writing
      #---------------------------------------

      def set_cksums_to_header
        headers[:puzzle_cksum] = puzzle_cksum
        headers[:header_cksum] = header_cksum
        headers[:icheated_cksum] = icheated_cksum
      end

      def write_to_io(io)
        io.write(header_data)
        io.write(solution_data)
        io.write(fill_data)
        io.write([title, author, copyright].join(?\0) + ?\0)
        io.write(clues.join(?\0) + ?\0)
        io.write((notes || '') + ?\0)
      end

      def header_data
        set_cksums_to_header

        parts = HEADER_PARTS.map do |k, v|
          headers[k] || (v[/a|Z/] ? '' : 0)
        end
        parts.pack(HEADER_FORMAT)
      end

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
        (data || '').each_byte do |b|
          lowbit = cksum & 1
          cksum = cksum >> 1
          cksum += 0x8000  unless lowbit.zero?
          cksum = (cksum + b) & 0xffff
        end
        cksum
      end

      def header_cksum
        headers[:clue_count] = clues.size

        format = HEADER_FORMAT[HEADER_CKSUM_RANGE]
        values = HEADER_PARTS.keys[HEADER_CKSUM_RANGE].map{|k| headers[k] || 0}

        checksum values.pack(format)
      end

      def puzzle_cksum
        data = [solution_data, fill_data, strings_section_for_cksum, clues.join,
                notes_for_cksum].join
        checksum data, header_cksum
      end

      def icheated_cksum
        cksums = [header_cksum, checksum(solution_data), checksum(fill_data),
                  checksum([strings_section_for_cksum, clues.join, notes_for_cksum].join)]
        lows, highs = [], []
        cksums.each_with_index do |cksum, idx|
          lows << (ICHEATED_MASK[idx] ^ (cksum & 0xFF))
          highs << (ICHEATED_MASK[idx + ICHEATED_MASK.size / 2] ^ ((cksum & 0xFF00) >> 8))
        end
        (lows + highs).pack('C*')
      end

      # title author and copyright followed by \0 if they are not empty
      def strings_section_for_cksum
        [title, author, copyright].reject{|s| !s || s.empty?}.map {|s| s + ?\0}.join
      end
      # notes + \0 if notes is not empty and version == 1.3
      def notes_for_cksum
        if version && version.to_s == '1.3'
          if notes && !notes.empty?
            notes + ?\0
          end
        end
      end
    end
  end
end
