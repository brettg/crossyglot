require 'spec_helper'

describe Formats::Puz do
  describe '#parse' do
    {'empty' => 'empty.puz', 'blank' => 'zeros.puz'}.each do |desc, filename|
      describe "for an #{desc} .puz file" do
        it 'should raise an InvalidPuzzleError' do
          lambda {
            Formats::Puz.new.parse(testfile_path(filename))
          }.should raise_error(InvalidPuzzleError)
        end
      end
    end

    describe 'for a .puz file' do
      describe 'with nothing out of the ordinary going on' do
        before do
          @puzzle = Formats::Puz.new.parse(testfile_path('vanilla.puz'))
        end

        it 'should be a Formats::Puz' do
          @puzzle.should be_kind_of(Formats::Puz)
        end
        it 'should set #version' do
          @puzzle.version.should == '1.2c'
        end
        it 'should set #width' do
          @puzzle.width.should == 15
        end
        it 'should set #height' do
          @puzzle.height.should == 15
        end
        it 'should set #clue_count' do
          @puzzle.clue_count.should == 76
        end

        it 'should set #title' do
          @puzzle.title.should == 'LA Times, Mon, Mar 26, 2012'
        end
        it 'should set #author' do
          @puzzle.author.should == 'Ki Lee / Ed. Rich Norris'
        end
        it 'should set #copyright' do
          @puzzle.copyright.should == "\xA9 2012 Tribune Media Services, Inc."
        end
        it 'should set #clues' do
          @puzzle.clues.should_not be_empty
          @puzzle.clues.size.should == 76
          @puzzle.clues.first.should == 'Filled tortilla'
          @puzzle.clues.last.should == 'Quiz, e.g.'
        end
        it 'should set #notes' do
          @puzzle.notes.should be_nil
        end
      end
    end
  end
end
