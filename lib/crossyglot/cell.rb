module Crossyglot
  # One square in the puzzle grid
  class Cell
    attr_accessor :number, :solution, :fill
    attr_accessor :has_across_clue, :has_down_clue, :is_incorrect, :is_black, :is_circled,
                  :was_previously_incorrect, :was_revealed

    # Returns a new Cell with is_black set to true
    def self.black
      new.tap {|c| c.is_black = true}
    end

    # Create a new Cell and set basic attributes
    def initialize(solution=nil, attribs={})
      self.solution = solution
      attribs.each do |k, v|
        if respond_to?(setter = "#{k}=")
          send(setter, v)
        end
      end
    end

    def circled?; !!@is_circled end
    def black?; !!@is_black end
    def incorrect?; !!@is_incorrect end
    def previously_incorrect?; !!@was_previously_incorrect end
    def revealed?; !!@was_revealed end

    def across?; !!(number && @has_across_clue) end
    def down?;  !!(number && @has_down_clue) end

    def rebus?
      solution && solution.size > 1
    end
    # True if the user filled in value is a rebus
    def rebus_fill?
      fill && fill.size > 1
    end
  end
end
