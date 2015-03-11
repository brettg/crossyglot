require 'spec_helper'

describe Puzzle do
  let(:puzzle) {Puzzle.new}

  describe '#cells' do
    it 'should default to an empty array' do
      puzzle.cells.should == []
    end
    it 'should keep additions around' do
      c = Cell.new
      puzzle.cells << c
      puzzle.cells.should == [c]
    end
  end

  {is_timer_running: :timer_running?, is_diagramless: :diagramless?}.each do |attr, pred|
    describe pred do
      it "should be true if #{attr} is set to true" do
        puzzle.send(pred).should == false
        puzzle.send("#{attr}=", true)
        puzzle.send(pred).should == true
      end
    end
  end

  describe '#cell_at' do
    before do
      puzzle.width = 5
      puzzle.height = 6
      puzzle.cells.concat (1..30).map {Cell.new}
    end
    it 'should return nil if x is out of bounds' do
      puzzle.cell_at(5, 0).should == nil
      puzzle.cell_at(-1, 0).should == nil
    end
    it 'should return nil if y is out of bounds' do
      puzzle.cell_at(0, 6).should == nil
      puzzle.cell_at(0, -1).should == nil
    end
    it 'should return nil if cells is empty' do
      puzzle.cells.clear
      puzzle.cell_at(0, 0).should == nil
    end
    it 'return cell based on width and height' do
      puzzle.cell_at(0, 0).should == puzzle.cells.first
      puzzle.cell_at(4, 5).should == puzzle.cells.last

      puzzle.cell_at(1, 0).should == puzzle.cells[1]
      puzzle.cell_at(0, 1).should == puzzle.cells[5]

      puzzle.cell_at(2, 3).should == puzzle.cells[17]
      puzzle.cell_at(3, 2).should == puzzle.cells[13]
    end
  end

  describe '#each_cell' do
    it 'should yield each cell left to right top to bottom with x and y coords' do
      cells = (1..15).map { Cell.new }
      puzzle.cells.concat cells
      wid = puzzle.width = 3
      hgt = puzzle.height = 5

      idx = 0
      puzzle.each_cell do |cell, x, y|
        (wid * y + x).should == idx
        x.should_not >= wid
        y.should_not >= hgt
        cell.should == cells[idx]

        idx += 1
      end
    end
  end

  describe '#acrosses_and_downs #across and #down' do
    #
    # Making grid like this ("-" is black):
    # 1 2 - 3
    # 4 . 5 .
    # 6 - 7 .
    #
    before do
      @puzzle = Puzzle.new
      clues = %w{1across 1down 2down 3across 3down 4across 5down 6across 7across}
      [[1, true, true], [2, false, true], false,            [3, true, true],
       [4, true],       [],               [5, false, true], [],
       [6, true],       false,            [7, true],        []].each do |cell_init|
        @puzzle.cells << if cell_init
          num, across, down = cell_init
          Cell.new('A',
                   number: num,
                   across_clue: across && clues.shift,
                   down_clue: down && clues.shift)
        else
          Cell.black
        end
      end
    end
    it 'shoud return hash of clues keyed by number for #acrosses' do
      exp = {1 => '1across', 3 => '3across', 4 => '4across', 6 => '6across', 7 => '7across'}
      @puzzle.acrosses.should == exp
    end
    it 'shoud return hash of clues keyed by number for #downs' do
      exp = {1 => '1down', 2 => '2down', 3 => '3down', 5 => '5down'}
      @puzzle.downs.should == exp
    end
    it 'should freeze both hashes' do
      @puzzle.acrosses.should be_frozen
      @puzzle.downs.should be_frozen
    end
    it 'should both be empty for a puzzle that has no clues or cells' do
      p = Puzzle.new
      p.acrosses.should == {}
      p.downs.should == {}
    end
  end
end
