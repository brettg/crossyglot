require 'spec_helper'

describe Puzzle do
  let(:puzzle) {Puzzle.new}

  describe '.parse' do
    it 'should create correct subclass and call #parse based on file extension'
  end

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
  describe '#clues' do
    it 'should default to an empty array' do
      puzzle.clues.should == []
    end
    it 'should keep additions around' do
      clue = 'hello!'
      puzzle.clues << clue
      puzzle.clues.should == [clue]
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

  describe '#acrosses_and_downs #accross and #down' do
    #
    # Making grid like this ("-" is black):
    # 1 2 - 3
    # 4 . 5 .
    # 6 - 7 .
    #
    before do
      @puzzle = Puzzle.new
      @puzzle.clues.concat %w{1across 1down 2down 3across 3down 4across 5down 6across 7across}
      [[1, true, true], [2, false, true], false,            [3, true, true],
       [4, true],       [],               [5, false, true], [],
       [6, true],       false,            [7, true],        []].each do |cell_init|
        @puzzle.cells << if cell_init
          num, across, down = cell_init
          Cell.new('A', number: num, has_across_clue: across, has_down_clue: down)
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
    it 'should not try to change clues' do
      @puzzle.clues.freeze
      lambda {@puzzle.acrosses}.should_not raise_error
    end

    it 'should both be empty for a puzzle that has no clues or cells' do
      p = Puzzle.new
      p.acrosses.should == {}
      p.downs.should == {}
    end
  end

  describe '#renumber_cells!' do
    describe 'for a puzzle with words longer than min word length' do
      before do
        puzzle = Puzzle.new
        grid = 'AAA.' +
               'AAAA' +
               '.AAA' +
               'AAA.' +
               'AAAA' +
               '.AAA'
        puzzle.width = 4
        puzzle.height = 6
        puzzle.cells.concat grid.chars.map{|l| l == ?. ? Cell.black : Cell.new(l)}
        puzzle.renumber_cells!(2)
      end
      it 'should set has_across_clue true to cells with no open cell to the left' do
        across_indices = [0, 4, 9, 12, 16, 21]
        puzzle.cells.each_with_index do |c, idx|
          unless c.black?
            c.has_across_clue.should == across_indices.include?(idx)
          end
        end
      end
      it 'should set has_down_clue true to cells with no open cell above' do
        down_indices = [0, 1, 2, 7, 12, 19]
        puzzle.cells.each_with_index do |c, idx|
          unless c.black?
            c.has_down_clue.should == down_indices.include?(idx)
          end
        end
      end
      it 'should give a number to cells that have an across or down clue' do
        nums = [1,   2,   3,   nil,
                4,   nil, nil, 5,
                nil, 6,   nil, nil,
                7,   nil, nil, nil,
                8,   nil, nil, 9,
                nil, 10,  nil, nil]
        puzzle.cells.zip(nums).each do |cell, num|
          cell.number.should == num
        end
      end
    end

    describe 'for puzzles with varying word lengths given a shorter word length' do
      it 'should not give shorter across words a number' do
        puzzle.width = 2
        puzzle.height = 1
        puzzle.cells.concat 2.times.map { Cell.new('A') }

        puzzle.renumber_cells!
        puzzle.cells.first.should_not be_across
        puzzle.cells.first.should_not be_down
        puzzle.cells.first.number.should be_nil

        puzzle.renumber_cells!(2)
        puzzle.cells.first.should be_across
        puzzle.cells.first.should_not be_down
        puzzle.cells.first.number.should == 1
      end
      it 'should not give shorter down words a number' do
        puzzle.width = 1
        puzzle.height = 6
        puzzle.cells.concat 6.times.map { Cell.new('A') }

        puzzle.renumber_cells!(7)
        puzzle.cells.first.should_not be_down
        puzzle.cells.first.should_not be_across
        puzzle.cells.first.number.should be_nil

        puzzle.renumber_cells!(6)
        puzzle.cells.first.should be_down
        puzzle.cells.first.should_not be_across
        puzzle.cells.first.number.should == 1
      end
      it 'should give numbers to all border cells with a min word length of one' do
        puzzle.width = puzzle.height = 1
        puzzle.cells << Cell.new('b')

        puzzle.renumber_cells!(1)
        puzzle.cells.first.number.should == 1
        puzzle.cells.first.should be_down
        puzzle.cells.first.should be_across
      end
    end
  end
end
