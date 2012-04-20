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

    # All the across clues in a(n ordered) hash keyed by number
    def acrosses
      collect_clues_by_number(:across?)
    end
    # All the down clues in a(n ordered) hash keyed by number
    def downs
      # not super efficient, having walk cells twice, but we'll punt until it becomes an issue
      collect_clues_by_number(:down?, (acrosses || []).size)
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

    # create the has for acrosses or downs
    # cell_flag_method is one of :down? or :across?
    # clue index is the first clue to start with in the clues array
    def collect_clues_by_number(cell_flag_method, clue_index=0)
      unless cells.empty? || clues.empty?
        cells.inject({}) do |accum, cell|
          if cell.send cell_flag_method
            accum[cell.number] = clues[clue_index]
            clue_index += 1
          end
          accum
        end.freeze
      end
    end
  end
end
