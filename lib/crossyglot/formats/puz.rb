module Crossyglot
  module Formats
    # Override the base Cell so we can save both the solution and fill values from the grid section
    # in the .puz file and the extra rebus sections
    class PuzCell < Cell
      # These will be used for the grid blocks of the .puz file. Generally they should
      # not be used externally in preference to only used #solution and #fill, which will both set
      # their puz_grid_* compliment to nil when set themself.
      attr_accessor :puz_grid_solution, :puz_grid_fill

      # Overriden to also set #puz_grid_solution to nil when #solution is set
      def solution=(new_solution)
        @puz_grid_solution = nil
        super
      end
      # Overridden to also set #puz_grid_fill to nil when #fill is set
      def fill=(new_fill)
        @puz_grid_fill = nil
        super
      end
    end

    # The .puz file format. See http://code.google.com/p/puz/wiki/FileFormat for info
    class Puz < Puzzle
      class InvalidChecksumError < InvalidPuzzleError; end

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
      HEADER_FORMAT = HEADER_PARTS.values.join
      # Range of header parts used in header checksum
      HEADER_CKSUM_RANGE = -5..-1

      PUZZLE_TYPES = {normal: 1, diagramless: 0x0401}
      SOLUTION_STATES = {normal: 0, scrambled: 4}

      HEADER_DEFAULTS = {magic: MAGIC, version: '1.3', puzzle_type: 1}


      STRINGS_SECTION_ENCODING = 'ISO-8859-1'

      EXTRA_SECTIONS = %w{GEXT LTIM GRBS RTBL RUSR}
      EXTRA_HEADER_FORMAT = 'a4vv'
      EXTRA_HEADER_LENGTH = 8

      # Map of attributes on Cell to mask bit to check against value for cell in GEXT extra section
      GEXT_MASKS = {is_incorrect: 0x20, was_previously_incorrect: 0x10,
                    was_revealed: 0x40, is_circled: 0x80}

      # FIXME - clean up the Rdociness of this (don't want this in rdoc, do want proxied methods in)
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

      # Override to read and write directly to headers
      def is_diagramless
        headers[:puzzle_type] == PUZZLE_TYPES[:diagramless]
      end
      def is_diagramless=(diagramless)
        headers[:puzzle_type] = PUZZLE_TYPES[diagramless ? :diagramless : :normal]
      end

      def is_scrambled
        headers[:solution_state] == SOLUTION_STATES[:scrambled]
      end
      def is_scrambled=(scrambled)
        headers[:solution_state] = SOLUTION_STATES[scrambled ? :scrambled : :normal]
      end

      def scrambled?; !!is_scrambled end

      # Parse the given puzzle.
      #
      # @param [String, IO] path_or_io The path on disk of the puzzle or an io containing the puzzle
      #                                data
      # @param [Boolean] strint Whether or not to check the checksums of the puzzle while parsing
      # @returns self
      def parse(path_or_io, strict=false)
        if path_or_io.is_a?(String)
          File.open(path_or_io,'rb:ASCII-8BIT') do |puzfile|
            parse_io(puzfile, strict)
          end
        else
          parse_io(path_or_io, strict)
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

      def parse_io(puzfile, strict)
        parse_header(puzfile)

        parse_solution(puzfile)

        parse_strings_sections(puzfile)

        renumber_cells(@parsed_clues)

        parse_extras(puzfile)

        @post_end ||= ''
        @post_end << puzfile.read

        validate_checksums  if strict
      end

      def parse_header(puzfile)
        puzfile.gets(MAGIC)

        # Magic wasn't found, assume file is not good
        raise InvalidPuzzleError.new('invalid .puz file')  if puzfile.eof?

        magic_start = puzfile.pos - MAGIC.size - 2

        puzfile.rewind

        @pre_magic = puzfile.read(magic_start)

        header_values = puzfile.read(HEADER_LENGTH).unpack(HEADER_FORMAT)
        HEADER_PARTS.keys.each_with_index do |name, idx|
          self.headers[name] = header_values[idx]
        end

        self.is_diagramless
      end

      def parse_solution(puzfile)
        solution = puzfile.read(width * height)
        fill = puzfile.read(width * height)

        cells.clear

        # Extra to_a prevents a segfault on ruby 1.9.2 (fixed in 1.9.3)
        solution.each_char.zip(fill.each_char.to_a) do |sol, fill|
          cells << if ?. == sol ||  ?: == sol
            Cell.black
          else
            PuzCell.new(sol, fill: fill == ?- ? nil : fill)
          end
        end

      end

      def parse_strings_sections(puzfile)
        self.title = next_string(puzfile)
        self.author = next_string(puzfile)
        self.copyright = next_string(puzfile)
        parse_clues(puzfile)
        self.notes = next_string(puzfile)
      end

      def parse_clues(puzfile)
        @parsed_clues = []
        headers[:clue_count].times {@parsed_clues << next_string(puzfile)}
      end

      def parse_extras(puzfile)
        @original_extras_order = []
        while header = puzfile.read(EXTRA_HEADER_LENGTH)
          if header.size == EXTRA_HEADER_LENGTH
            title, length, cksum = header.unpack(EXTRA_HEADER_FORMAT)
            body = puzfile.read(length + 1).chomp(?\0)

            meth = "parse_#{title.downcase}_section"
            send(meth, body)  if respond_to?(meth, true)
            # TODO - otherwise save unknown extra sections for roundtripping

            @original_extras_order << title
          else
            @post_end = header
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

          @grbs_section_body.each_byte.zip(cells) do |b, c|
            if b > 0
              grid_sol = c.solution
              c.solution = @original_rebuses_by_number[b - 1]
              # have to set this after setting solution because #solution= sets value to nil
              c.puz_grid_solution = grid_sol
            end
          end
        end
      end

      def parse_rusr_section(section_body)
        section_body.split(?\0).zip(cells) do |reb, c|
          if reb && reb.size > 0
            grid_fill = c.fill
            c.fill = reb
            # have to set this after setting solution because #fill= sets value to nil
            c.puz_grid_fill = grid_fill
          end
        end
      end

      # (Re)assigns number, across_clue and down_clue to each non black cell based on their position
      # in the grid and the minimum word length
      def renumber_cells(clues, min_word_length=3)
        num = 0
        # make sure we don't change original
        clues = clues.dup
        each_cell do |c, x, y|
          unless c.black?
            across = x == 0 || cell_at(x - 1, y).black?
            across &&= (min_word_length - 1).times.all? do |n|
              x1 = x + n + 1
              x1 < width && !cell_at(x1, y).black?
            end

            down = y == 0 || cell_at(x, y - 1).black?
            down &&= (min_word_length - 1).times.all? do |n|
              y1 = y + n + 1
              y1 < height && !cell_at(x, y1).black?
            end

            n = across || down ? num += 1 : nil

            c.across_clue = clues.shift  if across
            c.down_clue = clues.shift  if down

            c.number = n
          end
        end
      end

      # Next \0 delimited string from file, nil if of empty length
      def next_string(puzfile)
        s = puzfile.gets(?\0).chomp(?\0)
        s.empty? ? nil : s.force_encoding(STRINGS_SECTION_ENCODING).encode('UTF-8')
      end

      # Raise an error if the checksums in the headers hash do not match up
      def validate_checksums
        [:header_cksum, :puzzle_cksum, :icheated_cksum].each do |cksum|
          unless send(cksum) == headers[cksum]
            raise InvalidChecksumError.new("#{cksum.to_s.sub(/_/, ' ')} is invalid")
          end
        end
      end

      #---------------------------------------
      #   Strings methods encoded for writing
      #---------------------------------------
      %w{title author copyright notes}.each do |attr|
        define_method("encoded_#{attr}") do
          encode_string_data send(attr)
        end
      end
      def encoded_clues
        cells.inject([]) do |accum, c|
          accum << encode_string_data(c.across_clue)  if c.across?
          accum << encode_string_data(c.down_clue)  if c.down?
          accum
        end
      end
      def encode_string_data(s)
        s && s.encode(STRINGS_SECTION_ENCODING)
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
        io.write(@pre_magic)
        io.write(header_data)
        io.write(solution_data)
        io.write(fill_data)
        io.write(strings_data)
        io.write(extras_data)
        io.write(@post_end)
      end

      def header_data
        set_cksums_to_header

        parts = HEADER_PARTS.map do |k, v|
          headers[k] || (v[/a|Z/] ? '' : 0)
        end
        parts.pack(HEADER_FORMAT)
      end

      def solution_data
        cells.map do |c|
          if c.black?
            black_cell_char
          else 
            (c.respond_to?(:puz_grid_solution) && c.puz_grid_solution) || c.solution[0]
          end
        end.join
      end

      def fill_data
        cells.map do |c|
          if c.black?
            black_cell_char
          else
            (c.respond_to?(:puz_grid_fill) && c.puz_grid_fill) || (c.fill && c.fill[0]) || ?-
          end
        end.join
      end

      def black_cell_char
        diagramless? ? ?: : ?.
      end

      def strings_data
        all_strings = [encoded_title, encoded_author, encoded_copyright]
        all_strings.concat(encoded_clues).concat([encoded_notes, nil])
        all_strings.join(?\0)
      end


      def extras_data
        @grbs_body = @rbtl_body = nil

        @original_extras_order ||= []
        other_needed_sections = (EXTRA_SECTIONS - @original_extras_order).select do |s|
          send("#{s.downcase}_section_needed?")
        end

        (@original_extras_order + other_needed_sections).map do |s|
          extras_section_data(s, send("#{s.downcase}_section_data"))
        end.join
      end

      def gext_section_needed?
        cells.any? {|c| c.incorrect? || c.previously_incorrect? || c.revealed? || c.circled?}
      end
      def gext_section_data
        masks = cells.map do |cell|
          GEXT_MASKS.inject(0) do |accum, k_v|
            at, mask = k_v
            cell.send(at) ? accum | mask : accum
          end
        end
        masks.pack('C*')
      end

      def ltim_section_needed?
        timer_at || timer_running?
      end
      def ltim_section_data
        [timer_at.to_i, timer_running? ? '0' : '1'].join(',')
      end

      def grbs_section_needed?
        cells.any?(&:rebus?)
      end
      def grbs_section_data
        set_grbs_and_rtbl_section_data
        @grbs_body
      end

      alias_method :rtbl_section_needed?, :grbs_section_needed?
      def rtbl_section_data
        set_grbs_and_rtbl_section_data
        @rtbl_body
      end

      def rusr_section_needed?
        cells.any?(&:rebus_fill?)
      end
      def rusr_section_data
        cells.map {|c| c.rebus_fill? ? c.fill : nil}.join(?\0) << ?\0
      end

      # These sections need to be created together, this is how we prevent doing it twice while
      # maintaining the #{section_name}_section_data method naming scheme
      def set_grbs_and_rtbl_section_data
        unless @grbs_body
          rebus_strings = cells.select(&:rebus?).map(&:solution)
          # Preserve the original numbering, but also allow for new rebuses
          old_numbers = (@original_rebuses_by_number || {}).invert
          c = old_numbers.values.max || 0
          rebuses = rebus_strings.inject({}) do |accum, s|
            accum[s] = old_numbers[s] || (c += 1)
            accum
          end

          @grbs_body = cells.map {|c| c.rebus? ? rebuses[c.solution] + 1 : 0}.pack('C*')
          @rtbl_body = rebuses.sort_by{|v, n| n}.map{|v, n| '%2d:%s' % [n, v]}.join(';') + ';'
        end
      end

      # Put the title, body and size into the correct format
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
        headers[:clue_count] = encoded_clues.size

        format = HEADER_FORMAT[HEADER_CKSUM_RANGE]
        values = HEADER_PARTS.keys[HEADER_CKSUM_RANGE].map{|k| headers[k] || 0}

        checksum values.pack(format)
      end

      def puzzle_cksum
        data = [solution_data, fill_data, strings_section_for_cksum, encoded_clues.join,
                notes_for_cksum].join
        checksum data, header_cksum
      end

      def icheated_cksum
        cksums = [header_cksum, checksum(solution_data), checksum(fill_data),
                  checksum([strings_section_for_cksum, encoded_clues.join, notes_for_cksum].join)]
        lows, highs = [], []
        cksums.each_with_index do |cksum, idx|
          lows << (ICHEATED_MASK[idx] ^ (cksum & 0xFF))
          highs << (ICHEATED_MASK[idx + ICHEATED_MASK.size / 2] ^ ((cksum & 0xFF00) >> 8))
        end
        (lows + highs).pack('C*')
      end

      # title author and copyright followed by \0 if they are not empty
      def strings_section_for_cksum
        strings = [encoded_title, encoded_author, encoded_copyright]
        strings.reject{|s| !s || s.empty?}.map {|s| s + ?\0}.join
      end

      # notes + \0 if notes is not empty and version >= 1.4
      def notes_for_cksum
        if version && version.to_f >= 1.3
          if notes && !notes.empty?
            encoded_notes + ?\0
          end
        end
      end
    end
  end
end
