module Crossyglot
  # One square in the puzzle grid
  class Cell
    attr_accessor :number, :solution, :fill
    attr_writer :has_across_clue, :has_down_clue, :is_marked_incorrect, :is_black, :is_circled,
                :was_previously_marked_incorrect, :was_revealed

    # Returns a new Cell with is_black set to true
    def self.black
      new.tap {|c| c.is_black = true}
    end

    # Create a new Cell and set basic attributes
    def initialize(number=nil, across=false, down=false, solution=nil, fill=nil)
      self.number = number
      self.has_across_clue = across
      self.has_down_clue = down
      self.solution = solution
      self.fill = fill
    end

    def circled?; !!@is_circled end
    def black?; !!@is_black end
    def marked_incorrect?; !!@is_marked_incorrect end
    def previously_marked_incorrect?; !!@was_previously_marked_incorrect end
    def revealed?; !!@was_revealed end

    def across?; !!(number && @has_across_clue) end
    def down?;  !!(number && @has_down_clue) end
  end
end
