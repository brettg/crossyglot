require 'spec_helper'

describe Formats::PuzCell do
  let(:cell) {Formats::PuzCell.new}

  describe '#puz_grid_solution' do
    it 'should be nil by default' do
      cell.puz_grid_solution.should be_nil
    end
    it 'should be settable' do
      cell.puz_grid_solution = 'B'
      cell.puz_grid_solution.should == 'B'
    end
    it 'should get set to nil again when solution is set' do
      cell.instance_eval {@puz_grid_solution = 'A'}
      cell.solution = 'HELLO'
      cell.solution.should == 'HELLO'
      cell.puz_grid_solution.should be_nil
    end
  end
  describe '#puz_grid_fill' do
    it 'should be nil by default' do
      cell.puz_grid_fill.should be_nil
    end
    it 'should be settable' do
      cell.puz_grid_fill = 'B'
      cell.puz_grid_fill.should == 'B'
    end
    it 'should get set to nil again when fill is set' do
      cell.instance_eval {@puz_grid_fill = 'A'}
      cell.fill = 'HELLO'
      cell.fill.should == 'HELLO'
      cell.puz_grid_fill.should be_nil
    end
  end
  describe '#puz_is_rebus' do
    it 'should be nil by default' do
      cell.puz_is_rebus.should be_nil
    end
    it 'should be settable' do
      cell.puz_is_rebus = true
      cell.puz_is_rebus.should == true
    end
    it 'should get set to nil again when solution is set' do
      cell.puz_is_rebus = true
      cell.solution = 'A'
      cell.solution.should == 'A'
      cell.puz_is_rebus.should be_nil
    end
  end
  describe '#rebus?' do
    it 'should be false for normal solution' do
      cell.solution = 'A'
      cell.should_not be_rebus
    end
    it 'should be true for rebus solution' do
      cell.solution = 'ABC'
      cell.should be_rebus
    end
    it 'should be true if puz_is_rebus is true' do
      cell.puz_is_rebus = true
      cell.should be_rebus
    end
  end
end
