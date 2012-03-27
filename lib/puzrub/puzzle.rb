module Puzrub
  # The puzzle object
  class Puzzle
    attr_accessor :author, :copyright, :title

    def self.parse(path)
      p = new
      Formats::Puz.parse(path, p)
      p
    end

  end
end
