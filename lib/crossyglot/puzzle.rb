# TODO - Store clues as attributes in cells in the cell array instead of in their own array to be
#        more general instead of mimicking .puz files
module Crossyglot
  # The puzzle object
  class Puzzle
    attr_accessor :author, :copyright, :notes, :title
    attr_accessor :height, :width
    attr_accessor :timer_at, :is_timer_running
    attr_accessor :is_diagramless

    def self.parse(path)
      Formats::Puz.new.parse(path)
    end

    def timer_running?; !!is_timer_running end
    def diagramless?; !!is_diagramless end

    def cells
      @cells ||= []
    end

    # zero indexed x and y coordinates of cell with 0, 0 being the top right
    def cell_at(x, y)
      if cells && x < width && y < height && x >= 0 && y >= 0
        cells[y * width + x]
      end
    end

    # Yields each cell along with x and y coord in grid (zero indexed)
    def each_cell
      cells.each_with_index do |c, idx|
        yield c, *idx.divmod(width).reverse
      end
    end

    # All the across clues in a(n ordered) hash keyed by number
    def acrosses
      cells.inject({}) do |accum, c|
        accum[c.number] = c.across_clue if c.across?
        accum
      end.freeze
    end
    # All the down clues in a(n ordered) hash keyed by number
    def downs
      cells.inject({}) do |accum, c|
        accum[c.number] = c.down_clue if c.down?
        accum
      end.freeze
    end

  end
end
