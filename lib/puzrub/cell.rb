module Puzrub
  # One square in the puzzle grid
  class Cell
    attr_accessor :number, :is_black, :has_across_clue, :has_down_clue, :solution

    # Create a new Cell and set basic attributes
    def initialize(number=nil, across=false, down=false, solution=nil)
      self.number = number
      self.has_across_clue = across
      self.has_down_clue = down
      self.solution = solution
    end

    def self.black
      new.tap {|c| c.is_black = true}
    end

    def black?
      is_black
    end
    def across?
      number && has_across_clue
    end
    def down?
      number && has_down_clue
    end
  end
end
