require 'spec_helper'

describe Puzzle do
  describe '.parse' do
    describe 'for a .puz file' do
      describe 'with nothing out of the ordinary going on' do
        before do
          @puzzle = Puzzle.parse(File.expand_path('lat120326.puz', TESTFILE_DIR))
        end

        # TODO - make Puz a subclass of Puzzle to save extra info
        it 'should be a Puz'

        it 'should set #title' do
          @puzzle.title.should == 'LA Times, Mon, Mar 26, 2012'
        end
        it 'should set #author' do
          @puzzle.author.should == 'Ki Lee / Ed. Rich Norris'
        end
        it 'should set #copyright' do
          @puzzle.copyright.should == "\xA9 2012 Tribune Media Services, Inc."
        end

        it 'should set #clues'
        it 'should set #version'
      end
    end
  end
end
