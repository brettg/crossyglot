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
end
