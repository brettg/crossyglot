module Puzrub
  # The puzzle object
  class Puzzle
    attr_accessor :author, :clues, :copyright, :notes, :title
    attr_accessor :clue_count, :height, :width

    def self.parse(path)
      Formats::Puz.new.parse(path)
    end
  end
end
