# TODO - Store clues as attributes in cells in the cell array instead of in their own array to be
#        more general instead of mimicking .puz files
module Crossyglot
  # The puzzle object
  class Puzzle
    attr_accessor :author, :copyright, :notes, :title
    attr_accessor :height, :width
    attr_accessor :timer_at, :is_timer_running

    def self.parse(path)
      Formats::Puz.new.parse(path)
    end

    def timer_running?; !!@is_timer_running end

    def cells
      @cells ||= []
    end
    def clues
      @clues ||= []
    end

    # zero indexed x and y coord of cell with 0, 0 being the top right
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

    # TODO - these two could be more efficient.
    # All the across clues in a(n ordered) hash keyed by number
    def acrosses
      acrosses_and_downs.first
    end
    # All the down clues in a(n ordered) hash keyed by number
    def downs
      acrosses_and_downs.last
    end

    # (Re)assigns number, is_down and is_across to each non black cell based on their position in
    # the grid and the minimum word length
    def renumber_cells!(min_word_length=3)
      num = 0
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

          c.has_across_clue = across
          c.has_down_clue = down
          c.number = n
        end
      end
    end

    private

    def acrosses_and_downs
      cs = clues.dup
      cells.inject([{}, {}]) do |accum, cell|
        if cell.numbered?
          accum.first[cell.number] = cs.shift  if cell.across?
          accum.last[cell.number] = cs.shift  if cell.down?
        end
        accum
      end.map(&:freeze)
    end
  end
end
