require 'spec_helper'

describe Formats::Puz do
  describe '#cksum_region' do
    let(:puz) {Formats::Puz.new}
    it 'should return given checksum when data is empty' do
      puz.cksum_region('').should == 0
      puz.cksum_region('', 12345).should == 12345
    end
    describe 'for a bunch of values I calculated from the python or c lib' do
      {16556 => ['abc'], 32945 => ['def'], 41162 => ["\0\0\0afds"], 57536 => ['def', 123],
       49333 => ['a' * 100, 5]}.each do |checksum, args|
        arg_desc = args.inspect
        arg_desc = arg_desc.size > 30 ? "#{arg_desc[0,30]}..." : arg_desc
        it "should return a checksum of #{checksum} for #{arg_desc}" do
          puz.cksum_region(*args).should == checksum
        end
      end
    end
  end

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
        it 'should set #cells' do
          @puzzle.cells.should_not be_nil
          @puzzle.cells.size.should == 225

          first_cell = @puzzle.cells.first
          first_cell.solution.should == 'T'
          first_cell.should_not be_black
          first_cell.down_number.should == 1
          first_cell.across_number.should == 1

          second_cell = @puzzle.cells[1]
          second_cell.solution.should == 'A'
          second_cell.should_not be_black
          second_cell.down_number.should == 2
          second_cell.across_number.should be_nil

          first_black = @puzzle.cells[4]
          first_black.solution.should be_nil
          first_black.should be_black
          first_black.down_number.should be_nil
          first_black.across_number.should be_nil

          first_across_only = @puzzle.cells[15]
          first_across_only.solution.should == 'A'
          first_across_only.should_not be_black
          first_across_only.down_number.should be_nil
          first_across_only.across_number.should == 14

          first_numberless = @puzzle.cells[16]
          first_numberless.solution.should == 'S'
          first_numberless.should_not be_black
          first_numberless.down_number.should be_nil
          first_numberless.across_number.should be_nil

          last_cell = @puzzle.cells.last
          last_cell.solution.should == 'T'
          last_cell.should_not be_black
          last_cell.down_number.should be_nil
          last_cell.across_number.should be_nil
        end
      end
    end
  end

  describe '#write' do
    it 'should write a file to the given path'
  end
end
