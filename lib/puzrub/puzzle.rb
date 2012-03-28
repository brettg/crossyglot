module Puzrub
  # The puzzle object
  class Puzzle
    attr_accessor :author, :cells, :clues, :copyright, :notes, :title
    attr_accessor :clue_count, :height, :width

    def self.parse(path)
      Formats::Puz.new.parse(path)
    end

    def cell_at(x, y)
      if cells && x < width && y < height && x >= 0 && y >= 0
        cells[y * width + x]
      end
    end
  end
end
