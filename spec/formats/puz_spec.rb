require 'spec_helper'

describe Formats::Puz do
  let(:puz) {Formats::Puz.new}

  describe '#headers' do
    it 'should default to {}' do
      puz.headers.should == {}
    end
    it 'should be the same after updates' do
      puz.headers[:a] = :b
      puz.headers[:a].should == :b
    end
  end

  describe 'methods deferred to headers' do
    it 'should allow getting and setting' do
      puz.width = 4
      puz.width.should == 4
    end
  end

  describe '#checksum' do
    it 'should return given checksum when data is empty' do
      puz.send(:checksum, nil).should == 0
      puz.send(:checksum, '').should == 0
      puz.send(:checksum, '', 12345).should == 12345
    end
    describe 'for a bunch of values I calculated from the python or c lib' do
      {16556 => ['abc'], 32945 => ['def'], 41162 => ["\0\0\0afds"], 57536 => ['def', 123],
       49333 => ['a' * 100, 5]}.each do |checksum, args|
        arg_desc = args.inspect
        arg_desc = arg_desc.size > 30 ? "#{arg_desc[0,30]}..." : arg_desc
        it "should return a checksum of #{checksum} for #{arg_desc}" do
          puz.send(:checksum, *args).should == checksum
        end
      end
    end
  end

  describe '#header_cksum' do
    it 'should be the checksum of the last 5 header parts' do
      puz.headers.merge!(width: 15, height: 15, puzzle_type: 1, solution_state: 0)
      # clue count is inferred from number of clues, so add 76
      puz.clues.concat ['a'] * 76
      puz.send(:header_cksum).should == 55810

      puz.headers.merge!(width: 21, height: 21, puzzle_type: 1, solution_state: 0)
      puz.clues.clear
      puz.clues.concat ['a'] * 140
      puz.send(:header_cksum).should == 65028
    end
  end

  describe '#puzzle_cksum' do
    it 'should checksum the headers, solution, grid, clues, and strings' do
      puz.headers.merge!(width:  1, height: 1, puzzle_type: 1, solution_state: 0, version: '1.3')
      puz.send(:puzzle_cksum).should == 9728

      puz.clues << 'The letter before B'
      puz.send(:puzzle_cksum).should == 35852

      puz.cells << Cell.new(1, true, true, 'B')
      puz.send(:puzzle_cksum).should == 18374

      puz.title = ''
      puz.send(:puzzle_cksum).should == 18374

      puz.title = 'The Title'
      puz.send(:puzzle_cksum).should == 34377

      puz.author = 'Nobody, Really'
      puz.send(:puzzle_cksum).should == 37274

      puz.copyright = '20 oh 12!'
      puz.send(:puzzle_cksum).should == 44660

      puz.notes = ''
      puz.send(:puzzle_cksum).should == 44660

      puz.notes = 'Hardest puzzle possible'
      puz.send(:puzzle_cksum).should == 137
    end
    it 'should only include notes if version == 1.3' do
      puz.headers.merge!(width:  1, height: 1, puzzle_type: 1, solution_state: 0, version:'1.2')
      puz.notes = 'abc'
      puz.send(:puzzle_cksum).should == 9728

      # note version can be passed in as float
      puz.version = 1.3
      puz.send(:puzzle_cksum).should == 8886

      puz.version = nil
      puz.send(:puzzle_cksum).should == 9728
    end
  end

  describe '#icheated_cksum' do
    it 'should do a bunch of funky nonsense and calculate correctly' do
      puz.headers.merge!(width: 1, height: 1, clue_count: 1, puzzle_type: 1, solution_state: 0)
      puz.cells << Cell.new(1, true, true, 'B')
      puz.title = 'i cheated test'
      puz.author = 'the author'
      puz.copyright = '2000'
      puz.clues << 'first clue'
      puz.notes = 'the notes'

      puz.send(:icheated_cksum).should == "I\x01e\xecoTE\xd9"

      puz.version = '1.3'
      puz.send(:icheated_cksum).should == "I\x01e\x91oTE\xb2"
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

    describe 'for a fairly vanilla .puz' do
      before(:all) do
        @puzzle = Formats::Puz.new.parse(testfile_path('vanilla.puz'))
      end

      it 'should be a Formats::Puz' do
        @puzzle.should be_kind_of(Formats::Puz)
      end

      describe 'setting #headers' do
        it 'should set it to the same length as HEADER_PARTS' do
          @puzzle.headers.size.should == Formats::Puz::HEADER_PARTS.size
        end

        {puzzle_cksum: 41078,
         magic: Formats::Puz::MAGIC,
         header_cksum: 55810,
         magic_cksum: "\x4B\xED\x16\x69\x9B\x07\x37\xEE",
         version: '1.2c',
         unknown1: 0,
         scrambled_cksum: 0,
         unknown2: "\0\0\0\0\x35\x04\x91\x7C\x3E\x04\x91\x7C",
         width: 15,
         height: 15,
         clue_count: 76,
         puzzle_type: 1,
         solution_state: 0}.each do |header, val|
          it "should set :#{header}" do
            @puzzle.headers[header].should == val
          end
        end
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
      # FIXME - this test could be a lot more succinct if Cell#== just compared internals
      it 'should set #cells' do
        @puzzle.cells.should_not be_nil
        @puzzle.cells.size.should == 225

        {0 => [?T, false, true, true, 1], 1 => [?A, false, false, true, 2],
         4 => [nil, true, false, false, nil], 15 => [?A, false, true, false, 14],
         16 => [?S, false, false, false, nil], -1 => [?T, false, false, false, nil]
        }.each do |idx, cell_props|
          sol, blk, acr, dwn, num = cell_props
          cell = @puzzle.cells[idx]
          cell.solution.should == sol
          cell.black?.should == blk
          cell.across?.should == acr
          cell.down?.should == dwn
          cell.number.should == num
        end
      end
    end
    describe 'for a puzzle with the solution filled in' do
      it 'should set solution values to relevant cells'
    end
    describe 'for a puzzle cell with rebus cells' do
      it 'should set the rebus value of the appropriate cells'
    end
    describe 'for a puzzle with a scambled solution' do
      it 'should be #scrambled?'
    end
    describe 'for a diagramless puzzle' do
      it 'should be #diagramless?'
    end
  end

  describe '#write' do
    it 'should write a file to the given path'
  end

  describe '#solution_data' do
    it 'should return a string with the solution letters and dots for black cells' do
      puz.cells << Cell.new(nil, false, false, 'A')
      puz.cells << Cell.new(nil, false, false, 'B')
      puz.cells << Cell.new(nil, false, false, 'C')
      puz.cells << Cell.black
      puz.cells << Cell.new(nil, false, false, 'D')

      puz.send(:solution_data).should == 'ABC.D'
    end
  end

  describe '#fill_data' do
    it 'should return a string with a fill character for each cell with fill, a . or - otherwise' do
      3.times {puz.cells << Cell.new(nil, false, false, 'A')}
      puz.cells.last.fill = 'C'
      puz.cells << Cell.black
      puz.cells << Cell.new(nil, false, false, 'D')

      puz.send(:fill_data).should == '--C.-'
    end
  end
end
