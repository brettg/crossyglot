module Crossdress
  # The puzzle object
  class Puzzle
    attr_accessor :author, :copyright, :notes, :title
    attr_accessor :height, :width

    def self.parse(path)
      Formats::Puz.new.parse(path)
    end

    def cells
      @cells ||= []
    end
    def clues
      @clues ||= []
    end

    def cell_at(x, y)
      if cells && x < width && y < height && x >= 0 && y >= 0
        cells[y * width + x]
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
        end
      end
    end
  end
end
