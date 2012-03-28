require 'spec_helper'

describe Cell do

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
end
