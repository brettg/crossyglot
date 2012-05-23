require 'spec_helper'

describe Formats::PuzCell do
  let(:cell) {Formats::PuzCell.new}

  describe '#puz_grid_solution' do
    it 'should be nill by default' do
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
    it 'should be nill by default' do
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
end
