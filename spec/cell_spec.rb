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
    it 'should set fill with first arg' do
      c = Cell.new('A')
      c.solution.should == 'A'
    end
    it 'should set attributes with attr hash' do
      c = Cell.new('A', fill: 'B', number: 14, across_clue: 'across', down_clue: 'down')
      c.fill.should == 'B'
      c.number.should == 14
      c.should be_across
      c.down_clue.should == 'down'
    end
    it 'should ignore unknown attributes' do
      lambda {
        Cell.new('B', unknown_thingy: 'pants')
      }.should_not raise_error
    end
  end

  describe '.black' do
    it 'should return a new black cell' do
      c = Cell.black
      c.should be_kind_of(Cell)
      c.should be_black
    end
  end

  {is_incorrect: :incorrect?, is_black: :black?, is_circled: :circled?, number: :numbered?,
   was_previously_incorrect: :previously_incorrect?, was_revealed: :revealed?
  }.each do |attr, predicate|
    describe "##{predicate}" do
      it "should be true when @#{attr} is truthy" do
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
    it 'should be true if the solution\'s length is > 1' do
      Cell.new.should_not be_rebus
      Cell.new('A').should_not be_rebus
      Cell.new('5').should_not be_rebus
      Cell.new('AB').should be_rebus
    end
    it 'should be true if the solution is not an alphanumeric' do
      Cell.new('%').should be_rebus
      Cell.new('#').should be_rebus
    end
  end
  describe '#rebus_fill?' do
    it 'should be true if more than one letter is filled in' do
      Cell.new.should_not be_rebus_fill
      Cell.new('A').should_not be_rebus_fill
      Cell.new('AB', fill: 'A').should_not be_rebus_fill
      Cell.new('A', fill: '3').should_not be_rebus_fill
      Cell.new('A', fill: 'AB').should be_rebus_fill
      Cell.new('AB', fill: 'AB').should be_rebus_fill
    end
    it 'should be true if the fill is not an alphanumeric' do
      Cell.new('A', fill: ';').should be_rebus_fill
      Cell.new('A', fill: '+').should be_rebus_fill
    end
  end

  describe '#across?' do
    it 'should be true if @across_clue is set and number is set' do
      c = Cell.new
      c.should_not be_across
      c.across_clue = 'across'
      c.should_not be_across
      c.number = 5
      c.should be_across
      c.across_clue = nil
      c.should_not be_across
    end
  end
  describe '#down?' do
    it 'should be true if @down_clue is set and number is set' do
      c = Cell.new
      c.should_not be_down
      c.down_clue = 'down clue here!'
      c.should_not be_down
      c.number = 5
      c.should be_down
      c.down_clue = nil
      c.should_not be_down
    end
  end
end
