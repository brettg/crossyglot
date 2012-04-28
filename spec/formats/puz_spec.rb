require 'spec_helper'

describe Formats::Puz do
  let(:puz) {Formats::Puz.new}

  describe '#headers' do
    it 'should default to HEADER_DEFAULTS' do
      puz.headers.should == Formats::Puz::HEADER_DEFAULTS
    end
    it 'should be the same after updates' do
      puz.headers[:a] = :b
      puz.headers[:a].should == :b
    end
  end

  describe 'methods proxied to headers' do
    it 'should allow getting and setting' do
      puz.width = 4
      puz.width.should == 4

      puz.version = '1.2b'
      puz.headers[:version].should == '1.2b'
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

      puz.cells << Cell.new('B', number: 1, had_across_clue: 1, had_down_clue: 1)
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
      puz.headers.merge!(width: 1, height: 1, clue_count: 1, version: '1.2', puzzle_type: 1,
                         solution_state: 0)
      puz.cells << Cell.new('B', number: 1, had_across_clue: 1, had_down_clue: 1)
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
    before(:all) do
      @vanilla_puzzle = Formats::Puz.new.parse(testfile_path('vanilla.puz'))
      @partially_filled_puzzle = Formats::Puz.new.parse(testfile_path('partially-filled.puz'))
      @rebus_puzzle = Formats::Puz.new.parse(testfile_path('rebus.puz'))
      @unchecked_puzzle = Formats::Puz.new.parse(testfile_path('unchecked.puz'))
      @circles_puzzle = Formats::Puz.new.parse(testfile_path('circles.puz'))
      @user_rebus_puzzle = Formats::Puz.new.parse(testfile_path('user-rebus.puz'))
    end

    it 'should accept a path' do
      @vanilla_puzzle.title.should == 'LA Times, Mon, Mar 26, 2012'
    end
    it 'should accept an IO' do
      puz = File.open(testfile_path('vanilla.puz'), 'rb') do |f|
        Formats::Puz.new.parse(f)
      end
      puz.title.should == 'LA Times, Mon, Mar 26, 2012'
    end

    {'empty' => 'empty.puz', 'blank' => 'zeros.puz'}.each do |desc, filename|
      describe "for an #{desc} .puz file" do
        it 'should raise an InvalidPuzzleError' do
          lambda {
            Formats::Puz.new.parse(testfile_path(filename))
          }.should raise_error(InvalidPuzzleError)
        end
      end
    end

    it 'should be a Formats::Puz' do
      @vanilla_puzzle.should be_kind_of(Formats::Puz)
    end

    describe 'setting #headers' do
      it 'should set it to the same length as HEADER_PARTS' do
        @vanilla_puzzle.headers.size.should == Formats::Puz::HEADER_PARTS.size
      end

      {puzzle_cksum: 41078,
        magic: Formats::Puz::MAGIC,
        header_cksum: 55810,
        icheated_cksum: "\x4B\xED\x16\x69\x9B\x07\x37\xEE",
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
          @vanilla_puzzle.headers[header].should == val
        end
      end
    end

    it 'should set #version' do
      @vanilla_puzzle.version.should == '1.2c'
    end
    it 'should set #width' do
      @vanilla_puzzle.width.should == 15
    end
    it 'should set #height' do
      @vanilla_puzzle.height.should == 15
    end

    it 'should set #title' do
      @vanilla_puzzle.title.should == 'LA Times, Mon, Mar 26, 2012'
    end
    it 'should set #author' do
      @vanilla_puzzle.author.should == 'Ki Lee / Ed. Rich Norris'
    end
    it 'should set #copyright' do
      expected = "\xA9 2012 Tribune Media Services, Inc.".force_encoding('ISO-8859-1')
      @vanilla_puzzle.copyright.should == expected
    end
    it 'should set #clues' do
      @vanilla_puzzle.clues.should_not be_empty
      @vanilla_puzzle.clues.size.should == 76
      @vanilla_puzzle.clues.first.should == 'Filled tortilla'
      @vanilla_puzzle.clues.last.should == 'Quiz, e.g.'
    end
    it 'should set #notes' do
      @vanilla_puzzle.notes.should be_nil
    end
    it 'should set #cells' do
      @vanilla_puzzle.cells.should_not be_nil
      @vanilla_puzzle.cells.size.should == 225

      {0 => [?T, false, true, true, 1], 1 => [?A, false, false, true, 2],
        4 => [nil, true, false, false, nil], 15 => [?A, false, true, false, 14],
        16 => [?S, false, false, false, nil], -1 => [?T, false, false, false, nil]
      }.each do |idx, cell_props|
        sol, blk, acr, dwn, num = cell_props
        cell = @vanilla_puzzle.cells[idx]
        cell.solution.should == sol
        cell.black?.should == blk
        cell.across?.should == acr
        cell.down?.should == dwn
        cell.number.should == num
      end
    end

    it 'should set the encoding off all the strings to ISO-8859-1' do
      iso88591 = Encoding.find('ISO-8859-1')
      %w{title author copyright}.each do |attr|
        @vanilla_puzzle.send(attr).encoding.should == iso88591
      end

      @unchecked_puzzle.notes.encoding.should == iso88591

      @vanilla_puzzle.clues.each do |clue|
        clue.encoding.should == iso88591
      end
    end

    describe 'for a puzzle with the letters filled in' do
      it 'should set solution values to relevant cells' do
        {[0, 0] => ?A, [1, 0] => ?F, [2, 0] => ?T, [3, 0] => ?E, [4, 0] => ?R, [9, 0] => ?E,
         [4, 1] => ?A, [4, 2] => ?M, [7, 2] => ?K, [8, 2] => ?D, [4, 3] => ?B, [4, 4] => ?L,
         [4, 5] => ?E, [4, 6] => ?D, [0, 1] => nil}.each do |coords, f|
          cell = @partially_filled_puzzle.cell_at(*coords)
          cell.fill.should eq(f), "cell at #{coords.inspect} should == #{f}"
        end
      end
    end
    describe 'for a puzzle with checked and revealed cells' do
      it 'should set cells incorrect?' do
        @partially_filled_puzzle.cell_at(8, 2).should be_incorrect
      end
      it 'should set cells previously_incorrect?' do
        @partially_filled_puzzle.cell_at(9, 0).should be_previously_incorrect
      end
      it 'should set cells revealed?' do
        @partially_filled_puzzle.cell_at(7, 2).should be_revealed
      end
    end
    describe 'for a puzzle with timer data' do
      it 'should set timer_at' do
        @partially_filled_puzzle.timer_at.should == 180
      end
      it 'should set timer_running?' do
        @vanilla_puzzle.should_not be_timer_running
        @partially_filled_puzzle.should be_timer_running
      end
    end
    describe 'for a puzzle with circled cells' do
      it 'should set the correct cells to circled' do
        circled = [1, 16, 31, 33, 46, 48, 63, 65, 78, 80, 95, 97, 110, 112, 127, 129, 142, 144,
                   159, 161, 174, 176, 191, 193, 206, 208, 223, 238]
        @circles_puzzle.cells.each_with_index do |c, idx|
          c.circled?.should == circled.include?(idx)
        end
      end
    end
    describe 'for a puzzle with rebus cells' do
      it 'should set the rebus value of the appropriate cells' do
        %w{FA FA MI MI RE RE DO DO DO SOL SOL LA LA SOL}.each_with_index do |ans, idx|
          c = @rebus_puzzle.cells[idx + 105]
          c.should be_rebus
          c.solution.should == ans
        end
      end
    end
    describe 'for a puzzled with unchecked cells' do
      it 'should not give numbers to cells that start words of fewer than 3 letters' do
        c = @unchecked_puzzle.cell_at(6, 5)
        c.number.should be_nil
        c.should_not be_across
        c.should_not be_down
      end
    end
    describe 'for a puzzle with notes' do
      it 'should set the puzzle notes correctly' do
        @unchecked_puzzle.notes.should == "Due to the unusual structure of this grid," +
                                          " please note the following for solving in Across Lite" +
                                          "\r\n\r\n" +
                                          "Across Lite for Mac and Windows:\r\n" +
                                          "Use arrow keys or mouse to select the interior squares" +
                                          " to enter letters. Tab keys will not select them." +
                                          " There is no clue associated with these interior" +
                                          " squares.\r\n\r\n" +
                                          "Across Lite for iPad:\r\n" +
                                          "The interior letters CANNOT be entered in v3.0" +
                                          " of the app. \r\n"
      end
    end
    describe 'for a puzzle with user entered rebus cells' do
      it 'should set the user entries to the fill of the relevant cells' do
        @user_rebus_puzzle.cell_at(4, 3).fill.should == 'HELLO'
        @user_rebus_puzzle.cell_at(5, 4).fill.should == 'THERE'
      end

      it 'should not set anything to other cells' do
        @user_rebus_puzzle.cell_at(0, 0).fill.should be_nil
      end
    end
    describe 'for a puzzle with a scambled solution' do
      it 'should be #scrambled?'
    end
    describe 'for a diagramless puzzle' do
      it 'should be #diagramless?'
    end
  end

  describe '#write' do
    it 'should write to an IO given an IO' do
      io = StringIO.new
      puz.write(io)
      data = io.string
      data.size.should > 0
    end
    it 'should write a file to the given a path' do
      tmp_output_path('puzwrite') do |tmp_path|
        puz.write(tmp_path)
        File.exists?(tmp_path).should be_true
      end
    end

    # Testing via round tripping seems like the easiest and most complete way to exercise all the
    # writing logic.
    describe 'should correctly roundtrip' do
      %w{vanilla partially-filled rebus unchecked circles other-extras-order
         user-rebus}.each do |fn|
        it "#{fn}.puz" do
          should_roundtrip_puz_file testfile_path("#{fn}.puz")
        end
      end
    end
  end

  describe '#solution_data' do
    it 'should return a string with the (first) solution letters and dots for black cells' do
      puz.cells << Cell.new('A')
      puz.cells << Cell.new('B')
      puz.cells << Cell.new('C')
      puz.cells << Cell.black
      puz.cells << Cell.new('DD')

      puz.send(:solution_data).should == 'ABC.D'
    end
  end

  describe '#fill_data' do
    it 'should return a string with a fill character for each cell with fill, a . or - otherwise' do
      3.times {puz.cells << Cell.new('A')}
      puz.cells.last.fill = 'C'
      puz.cells << Cell.black
      puz.cells << Cell.new('D')

      puz.send(:fill_data).should == '--C.-'
    end
    it 'should just return first letter if the user has entered a rebus' do
      puz.cells << Cell.new('A', fill: 'ABC')
      puz.send(:fill_data).should == 'A'
    end
  end

  describe '#strings_data' do
    it 'should write strings in ISO-8859-1' do
      # copyright character is different between latin1 and UTF-8
      puz.clues << "\xA9".force_encoding('ISO-8859-1').encode('UTF-8')
      puz.send(:strings_data).bytes.to_a.should == [0, 0, 0, 0xA9, 0, 0]
    end
  end

  describe '#extras_data' do
    it 'should be empty by default' do
      puz.send(:extras_data).should == ''
    end
    it 'should include sections in @original_extras_order' do
      puz.instance_eval {@original_extras_order = %w(GEXT LTIM)}
      puz.send(:extras_data).should match(/GEXT/)
      puz.send(:extras_data).should match(/LTIM/)
    end
    describe 'should include GEXT if' do
      [:is_incorrect, :was_previously_incorrect, :was_revealed].each do |attr|
        it "a cell has #{attr} set" do
          cell = Cell.new
          cell.send("#{attr}=", true)
          puz.cells << cell

          puz.send(:extras_data).should match(/GEXT/)
        end
      end
    end
    describe 'should include LTIM if' do
      it 'timer_at is set' do
        puz.timer_at = 0
        puz.send(:extras_data).should match(/LTIM/)
        puz.timer_at = 200
        puz.send(:extras_data).should match(/LTIM/)
      end
      it 'timer_running is true' do
        puz.is_timer_running = true
        puz.send(:extras_data).should match(/LTIM/)
      end
    end
    it 'should include both GRBS and RTBL if a cell has a rebus' do
      puz.cells << Cell.new('ABC')
      puz.send(:extras_data).should match(/GRBS/)
      puz.send(:extras_data).should match(/RTBL/)
    end

    it 'should include RUSR if a cell has rebus fill' do
      puz.cells << Cell.new('A', fill: 'ABC')
      puz.send(:extras_data).should match(/RUSR/)
    end
  end

  describe '#extras_section_data' do
    it 'should return extras section with header and body' do
      puz.send(:extras_section_data, 'LTIM', '180,0').should == "LTIM\x05\x00\\\x10180,0\x00"
    end
  end
end
