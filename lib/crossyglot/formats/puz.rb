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

      EXTRA_HEADER_FORMAT = 'a4vv'
      EXTRA_HEADER_LENGTH = 8

      # Map of attributes on Cell to mask bit to check against value for cell in GEXT extra section
      GEXT_MASKS = {is_incorrect: 0x20, was_previously_incorrect: 0x10,
                    was_revealed: 0x40} #, is_circled: 0x80}

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

        parse_extras(puzfile)
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

            Cell.new(sol, fill: c_fill, number: number, has_across_clue: across, has_down_clue: down)
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

      def parse_extras(puzfile)
        while header = puzfile.gets(EXTRA_HEADER_LENGTH)
          if header.size == EXTRA_HEADER_LENGTH
            title, length, cksum = header.unpack(EXTRA_HEADER_FORMAT)
            body = puzfile.gets(length + 1).chomp(?\0)

            meth = "parse_#{title.downcase}_section"
            send(meth, body)  if respond_to?(meth, true)
            # TODO - otherwise save unknown extra sections for roundtripping
            # TODO - save extra section order for roundtripping???
          end
        end
      end

      def parse_gext_section(section_body)
        section_body.bytes.zip(cells).each do |b, cell|
          GEXT_MASKS.each do |cell_meth, mask|
            cell.send "#{cell_meth}=", !(b & mask).zero?
          end
        end
      end

      def parse_ltim_section(section_body)
        self.timer_at, running = section_body.split(',').map(&:to_i)
        self.is_timer_running = running.zero?
      end

      # Both are needed so just store into instance var until we have both
      def parse_grbs_section(section_body)
        @grbs_section_body = section_body
        parse_rtbl_and_grbs_sections
      end
      def parse_rtbl_section(section_body)
        @rtbl_section_body = section_body
        parse_rtbl_and_grbs_sections
      end
      def parse_rtbl_and_grbs_sections
        if @grbs_section_body && @rtbl_section_body
          rebus_pairs = @rtbl_section_body.split(';').map {|s| p = s.split(':'); [p[0].to_i, p[1]]}
          @original_rebuses_by_number = Hash[rebus_pairs]

          @grbs_section_body.bytes.with_index do |b, idx|
            if b > 0
              cells[idx].solution = @original_rebuses_by_number[b - 1]
            end
          end
        end
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
        io.write(notes)
        io.write(?\0)
        io.write(extras_data)
      end

      def header_data
        set_cksums_to_header

        parts = HEADER_PARTS.map do |k, v|
          headers[k] || (v[/a|Z/] ? '' : 0)
        end
        parts.pack(HEADER_FORMAT)
      end

      def solution_data
        cells.map {|c| c.black? ? ?. : c.solution[0]}.join
      end

      def fill_data
        cells.map {|c| c.fill || (c.black? ? ?. : ?-)}.join
      end

      def extras_data
        [ltim_section_data, gext_section_data, grbs_and_rtbl_section_data].join
      end

      def gext_section_data
        if cells.any? {|c| c.incorrect? || c.previously_incorrect? || c.revealed?}
          masks = cells.map do |cell|
            GEXT_MASKS.inject(0) do |accum, k_v|
              at, mask = k_v
              cell.send(at) ? accum | mask : accum
            end
          end
          extras_section_data('GEXT', masks.pack('C*'))
        end
      end
      def ltim_section_data
        if timer_at || timer_running?
          extras_section_data('LTIM', [timer_at.to_i, timer_running? ? '0' : '1'].join(','))
        end
      end

      def grbs_and_rtbl_section_data
        if cells.any?(&:rebus?)
          rebus_strings = cells.select(&:rebus?).map(&:solution)
          # Preserve the original numbering, but also allow for new rebuses
          old_numbers = (@original_rebuses_by_number || {}).invert
          c = old_numbers.values.max || 0
          rebuses = rebus_strings.inject({}) do |accum, s|
            accum[s] = old_numbers[s] || (c += 1)
            accum
          end

          grbs_body = cells.map {|c| c.rebus? ? rebuses[c.solution] + 1 : 0}.pack('C*')
          rtbl_body = rebuses.sort_by{|v, n| n}.map{|v, n| '%2d:%s' % [n, v]}.join(';') + ';'

          extras_section_data('GRBS', grbs_body) + extras_section_data('RTBL', rtbl_body)
        end
      end

      def extras_section_data(title, body)
        [title, body.size, checksum(body)].pack(EXTRA_HEADER_FORMAT) + body + ?\0
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
