require 'spec_helper'

describe Cell do

  describe '.new' do
    it 'should set nothing with no args' do
      c = Cell.new
      c.number.should be_nil
      c.should_not be_across
      c.should_not be_down
      c.solution.should be_nil
    end
    it 'should set number, down, across, and solution' do
      c = Cell.new(14, true, false, 'A')
      c.number.should == 14
      c.should be_across
      c.should_not be_down
      c.solution.should == 'A'
    end
  end

  describe '.black' do
    it 'should return a new black cell' do
      c = Cell.black
      c.should be_kind_of(Cell)
      c.should be_black
    end
  end

  describe '#black?' do
    it 'should be true if @is_black is truthy' do
      c = Cell.new
      c.should_not be_black
      c.is_black = 'helllo!'
      c.should be_black
      c.is_black = false
      c.should_not be_black
    end
  end
  describe '#across?' do
    it 'should be true if @has_across_clue is true and number is set' do
      c = Cell.new
      c.should_not be_across
      c.has_across_clue = true
      c.should_not be_across
      c.number = 5
      c.should be_across
      c.has_across_clue = false
      c.should_not be_across
    end
  end
  describe '#down?' do
    it 'should be true if @has_down_clue is true and number is set' do
      c = Cell.new
      c.should_not be_down
      c.has_down_clue = true
      c.should_not be_down
      c.number = 5
      c.should be_down
      c.has_down_clue = false
      c.should_not be_down
    end
  end
end
