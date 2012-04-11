require 'spec_helper'

describe Cell do
  let(:cell) {Cell.new}

  describe '.new' do
    it 'should set nothing with no args' do
      cell.number.should be_nil
      cell.should_not be_across
      cell.should_not be_down
      cell.solution.should be_nil
    end
    it 'should set number, down, across, and solution' do
      c = Cell.new(14, true, false, 'A', 'B')
      c.number.should == 14
      c.should be_across
      c.should_not be_down
      c.solution.should == 'A'
      c.fill.should == 'B'
    end
  end

  describe '.black' do
    it 'should return a new black cell' do
      c = Cell.black
      c.should be_kind_of(Cell)
      c.should be_black
    end
  end

  {is_marked_incorrect: :marked_incorrect?, is_black: :black?, is_circled: :circled?,
   was_previously_marked_incorrect: :previously_marked_incorrect?, was_revealed: :revealed?
  }.each do |attr, predicate|
    describe "##{predicate}" do
      it "should be true when @#{attr} is true" do
        set_method = "#{attr}="

        cell.send(predicate).should == false

        cell.send(set_method, 'helllo!')
        cell.send(predicate).should == true

        cell.send(set_method, nil)
        cell.send(predicate).should == false
      end
    end
  end

  describe '#rebus?' do
    it 'should be true if the solution\'s length is > 1'
  end
  describe '#rebus_fill?' do
    it 'should be true if more than one letter is filled in'
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
