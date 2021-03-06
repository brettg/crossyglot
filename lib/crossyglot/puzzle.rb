module Crossyglot
  # The base puzzle object containing puzzle data and common functionality. Subclasses are needed
  # for parsing and writing out specific file types.
  class Puzzle
    # For format classes to register themselves.
    FORMAT_EXTENSIONS = {}

    ATTRIBUTES = :author, :copyright, :notes, :title, :description,
                 :height, :width,
                 :timer_at, :is_timer_running,
                 :is_diagramless
    attr_accessor(*ATTRIBUTES)

    def timer_running?; !!is_timer_running end
    def diagramless?; !!is_diagramless end

    # Parse the given puzzle determining type by file extension.
    #
    # @param [String] path The path of the puzzle to parse. Extension must be one of:
    #                      .puz .jpz
    # @returns [Puzzle]
    def self.parse_file(path)
      ext = path && File.extname(path)
      if ext && clazz = FORMAT_EXTENSIONS[ext.sub(/\A\./, '')]
        clazz.new.parse_file(path)
      else
        raise Crossyglot::InvalidExtensionError.new("Unknown puzzle extension: #{ext}")
      end
    end

    # Parse the given puzzle. Passes to parse_file or parse_io method of subclass.
    #
    # @param [String, IO] path_or_io The path on disk of the puzzle or a subclass of IO containing
    #                                the puzzle data
    # @param [Hash] strict Options to pass to parse_io or parse_file method (see subclasses)
    # @returns [Puzzle] self
    def parse(path_or_io, options={})
      public_send(path_or_io.is_a?(String) ? :parse_file : :parse_io, path_or_io, options)
      self
    end

    # Write out the given puzzle. Passes to write_file or write_io method of subclass.
    #
    # @param [String, IO] path_or_io The path on disk to be written or an IO object to write to
    def write(path_or_io)
      public_send(path_or_io.is_a?(String) ? :write_file : :write_io, path_or_io)
    end

    # The array of cell objects which correspond to squares (black or white) in the puzzle grid.
    # Manipulate the puzzle by manipulating the number, order and properties of the cells.
    #
    # @returns [Array]
    def cells
      @cells ||= []
    end

    # zero indexed x and y coordinates of cell with 0, 0 being the top right
    #
    # @param [Fixnum] x
    # @param [Fixnum] y
    # @returns [Cell]
    def cell_at(x, y)
      if cells && x < width && y < height && x >= 0 && y >= 0
        cells[y * width + x]
      end
    end

    # Yields each cell along with x and y coord in grid (zero indexed)
    def each_cell
      cells.each_with_index do |c, idx|
        yield c, *(width ? idx.divmod(width).reverse : nil)
      end
    end

    # All the across clues in a(n ordered) hash keyed by number
    #
    # @returns [Hash]
    def acrosses
      cells.inject({}) do |accum, c|
        accum[c.number] = c.across_clue if c.across?
        accum
      end.freeze
    end
    # All the down clues in a(n ordered) hash keyed by number
    #
    # @returns [Hash]
    def downs
      cells.inject({}) do |accum, c|
        accum[c.number] = c.down_clue if c.down?
        accum
      end.freeze
    end

    # The total number of word answers (and thus clues).
    #
    # @returns [Fixnum]
    def word_count
      cells.inject(0) { |a, c| a + (c.across? ? 1 : 0) + (c.down? ? 1 : 0) }
    end

    # Convert to a different format subclass.
    #
    # @param [Class, string] The class name of file extension of the format to conver to.
    # @returns [Puzzle] A new puzzle object of the appropriate class, or this puzzle object if the
    #                   class is the same. Raises an InvalidPuzzleFormat if given something bogus.
    def convert_to(format)
      clazz = FORMAT_EXTENSIONS[format.to_s] || format
      raise InvalidPuzzleFormat.new  unless FORMAT_EXTENSIONS.values.include?(clazz)

      if kind_of?(clazz)
        self
      else
        new_puzzle = clazz.new
        ATTRIBUTES.each do |attr|
          new_puzzle.public_send("#{attr}=", public_send(attr))
        end
        new_puzzle.cells.concat(cells.map(&:clone))
        new_puzzle
      end
    end

    def eql?(other)
      attrs_eql?(other) && cells_eql?(other)
    end

    private

    # Calculate and update #across_length and #down_length for each cell. Should be called by all
    # subclasses after setting of #cells is complete.
    def update_word_lengths!
      each_cell do |cell, x, y|
        cell.across_length = cell.across? ? word_length(x, y, 1, 0) : nil
        cell.down_length = cell.down? ? word_length(x, y, 0, 1) : nil
      end
    end

    def attrs_eql?(other)
      %i{
        author copyright notes title description height width timer_at
        timer_running?  diagramless?
      }.all? do |attr|
        public_send(attr).eql?(other.public_send(attr))
      end
    end

    def cells_eql?(other)
      cells.size == other.cells.size && cells.zip(other.cells).all? { |c1, c2| c1.eql?(c2) }
    end

    # Internal word length calculation. Assumes the cell at x, y should be counted.
    def word_length(x, y, xstep, ystep)
      n = 0
      begin
        n += 1
        x, y = [x + xstep, y + ystep]
        cell = cell_at(x, y)
      end  until !cell || cell.black?
      n
    end
  end
end
