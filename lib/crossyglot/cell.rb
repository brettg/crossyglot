module Crossyglot
  # One square in the puzzle grid
  class Cell
    NON_REBUS_CHARS = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a

    attr_accessor :number, :solution, :fill,
                  :across_clue, :down_clue,
                  :down_length, :across_length,
                  :is_incorrect, :is_black, :is_circled,
                  :was_previously_incorrect, :was_revealed

    # Returns a new Cell with is_black set to true
    def self.black
      new.tap { |c| c.is_black = true }
    end

    # Create a new Cell and set basic attributes
    def initialize(solution=nil, attribs={})
      self.solution = solution
      attribs.each do |k, v|
        if respond_to?(setter = "#{k}=")
          public_send(setter, v)
        end
      end
    end

    def black?; !!@is_black end
    def circled?; !!@is_circled end
    def incorrect?; !!@is_incorrect end
    def numbered?; !!@number end
    def previously_incorrect?; !!@was_previously_incorrect end
    def revealed?; !!@was_revealed end

    def across?; !!(number && @across_clue) end
    def down?;  !!(number && @down_clue) end

    def rebus?
      rebus_value?(solution)
    end
    # True if the user filled in value is a rebus
    def rebus_fill?
      rebus_value?(fill)
    end

    def eql?(other)
      %i{number solution fill
         across_clue down_clue
         down_length across_length
         incorrect? black? circled?
         previously_incorrect? revealed?}.all? do |attr|
        public_send(attr).eql?(other.public_send(attr))
      end
    end

    private

    # This appears to be inconsistent. Puzzles with single character ISO-8859-1 cells can be treated
    # as non-rebus, but fill of the same type will often cause the fill section to be saved as
    # rebus.
    def rebus_value?(v)
      v && v.size > 1
    end
  end
end
