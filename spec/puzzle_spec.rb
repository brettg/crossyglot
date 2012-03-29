require 'spec_helper'

describe Puzzle do
  describe '.parse' do
    it 'should create correct subclass and call #parse based on file extension'
  end

  describe '#cell_at' do
    before do
      @puzzle = Puzzle.new
      @puzzle.width = 5
      @puzzle.height = 6
      @puzzle.cells = (1..30).map {Cell.new}
    end
    it 'should return nil if x is out of bounds' do
      @puzzle.cell_at(5, 0).should == nil
      @puzzle.cell_at(-1, 0).should == nil
    end
    it 'should return nil if y is out of bounds' do
      @puzzle.cell_at(0, 6).should == nil
      @puzzle.cell_at(0, -1).should == nil
    end
    it 'should return nil if cells is nil' do
      @puzzle.cells = nil
      @puzzle.cell_at(0, 0).should == nil
    end
    it 'return cell based on width and height' do
      @puzzle.cell_at(0, 0).should == @puzzle.cells.first
      @puzzle.cell_at(4, 5).should == @puzzle.cells.last

      @puzzle.cell_at(1, 0).should == @puzzle.cells[1]
      @puzzle.cell_at(0, 1).should == @puzzle.cells[5]

      @puzzle.cell_at(2, 3).should == @puzzle.cells[17]
      @puzzle.cell_at(3, 2).should == @puzzle.cells[13]
    end
  end

  describe '#accross and #down' do
    #
    # Making grid like this ("-" is black):
    # 1 2 - 3
    # 4 . 5 .
    # 6 - 7 .
    #
    before do
      @puzzle = Puzzle.new
      @puzzle.clues = %w{1across 3across 4across 6across 7across 1down 2down 3down 5down}
      @puzzle.cells = []
      [[1, true, true], [2, false, true], false,            [3, true, true],
       [4, true],       [],               [5, false, true], [],
       [6, true],       false,            [7, true],        []].each do |cell_init|
        @puzzle.cells << (cell_init ? Cell.new(*cell_init) : Cell.black)
      end
    end
    it 'shoud return hash of clues keyed by number for #acrosses' do
      @puzzle.acrosses.should == {1 => '1across', 3 => '3across', 4 => '4across', 6 => '6across',
                                  7 => '7across'}
    end
    it 'shoud return hash of clues keyed by number for #downs' do
      @puzzle.downs.should == {1 => '1down', 2 => '2down', 3 => '3down', 5 => '5down'}
    end

    it 'should both be nil for a puzzle that has no clues or cells' do
      p = Puzzle.new
      p.acrosses.should be_nil
      p.downs.should be_nil
    end
  end

end
