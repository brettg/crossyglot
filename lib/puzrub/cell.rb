module Puzrub
  # One square in the puzzle grid
  class Cell
    attr_accessor :across_number, :down_number, :is_black, :solution

    def black?
      is_black
    end
  end
end
