require 'spec_helper'

describe Puzzle do
  let(:puzzle) { Puzzle.new }

  describe '#parse_file' do
    let(:path) { }
    let(:puzzle) { Puzzle.parse_file(path) }
    subject { puzzle }

    context 'for nil' do
      it 'raises an unknown extension error' do
        expect { subject }.to raise_exception(Crossyglot::InvalidExtensionError)
      end
    end
    context 'for .puz file' do
      let(:path) { testfile_path('vanilla.puz') }
      it('returns a Formats::Puz file') { is_expected.to be_kind_of(Formats::Puz) }
    end
    context 'for .jpz file' do
      let(:path) { testfile_path('basic-zipped.jpz') }
      it('returns a Formats::Jpz file') { is_expected.to be_kind_of(Formats::Jpz) }
    end
    context 'for an unknown file extension' do
      let(:path) { testfile_path('puzzle.cats') }
      it 'raises an unknown extension error' do
        expect { subject }.to raise_exception(Crossyglot::InvalidExtensionError)
      end
    end
    context 'for a file that does not exist' do
      let(:path) { testfile_path('cats.puz') }
      it 'raises an no such file error' do
        expect { subject }.to raise_exception(Errno::ENOENT)
      end
    end
  end

  describe '#cells' do
    it 'defaults to an empty array' do
      puzzle.cells.should == []
    end
    it 'keeps additions around' do
      c = Cell.new
      puzzle.cells << c
      puzzle.cells.should == [c]
    end
  end

  {is_timer_running: :timer_running?, is_diagramless: :diagramless?}.each do |attr, pred|
    describe pred do
      it "should be true if #{attr} is set to true" do
        puzzle.send(pred).should == false
        puzzle.send("#{attr}=", true)
        puzzle.send(pred).should == true
      end
    end
  end

  describe '#cell_at' do
    let(:puzzle) do
      super().tap do |p|
        p.width = 5
        p.height = 6
        p.cells.concat (1..30).map { Cell.new }
      end
    end

    it 'should return nil if x is out of bounds' do
      puzzle.cell_at(5, 0).should == nil
      puzzle.cell_at(-1, 0).should == nil
    end
    it 'should return nil if y is out of bounds' do
      puzzle.cell_at(0, 6).should == nil
      puzzle.cell_at(0, -1).should == nil
    end
    it 'should return nil if cells is empty' do
      puzzle.cells.clear
      puzzle.cell_at(0, 0).should == nil
    end
    it 'return cell based on width and height' do
      puzzle.cell_at(0, 0).should == puzzle.cells.first
      puzzle.cell_at(4, 5).should == puzzle.cells.last

      puzzle.cell_at(1, 0).should == puzzle.cells[1]
      puzzle.cell_at(0, 1).should == puzzle.cells[5]

      puzzle.cell_at(2, 3).should == puzzle.cells[17]
      puzzle.cell_at(3, 2).should == puzzle.cells[13]
    end
  end

  describe '#each_cell' do
    it 'should yield each cell left to right top to bottom with x and y coords' do
      cells = (1..15).map { Cell.new }
      puzzle.cells.concat cells
      wid = puzzle.width = 3
      hgt = puzzle.height = 5

      idx = 0
      puzzle.each_cell do |cell, x, y|
        expect(wid * y + x).to eql(idx)
        expect(x).not_to be >= wid
        expect(y).not_to be >= hgt
        expect(cell).to eql(cells[idx])

        idx += 1
      end
    end
  end

  let(:ad_puzzle_clues) { %w{1across 1down 2down 3across 3down 4across 5down 6across 7across} }
  let(:ad_puzzle_cells) do
    #
    # Making grid like this ("-" is black):
    # 1 2 - 3
    # 4 . 5 .
    # 6 - 7 .
    #
    clues = ad_puzzle_clues.dup
    [[1, true, true], [2, false, true], false,            [3, true, true],
     [4, true],       [],               [5, false, true], [],
     [6, true],       false,            [7, true],        []].map do |cell_init|
      if cell_init
        num, across, down = cell_init
        Cell.new('A',
                  number: num,
                  across_clue: across && clues.shift,
                  down_clue: down && clues.shift)
      else
        Cell.black
      end
    end
  end
  let(:ad_puzzle) do
    Puzzle.new.tap do |p|
      p.cells.concat ad_puzzle_cells
      p.width = 4
      p.height = 3
    end
  end

  describe '#acrosses' do
    subject { puzzle.acrosses }

    context 'for a puzzle with no clues' do
      it('returns an empty hash') { expect(subject).to eql({}) }
      it('that is froze') { expect(subject).to be_frozen }
    end

    context 'for a puzzle with clues' do
      let(:puzzle) { ad_puzzle }

      it 'returns hash of clues keyed by number for #acrosses' do
        exp = {1 => '1across', 3 => '3across', 4 => '4across', 6 => '6across', 7 => '7across'}
        expect(subject).to eql(exp)
      end
    end
  end

  describe '#downs' do
    subject { puzzle.downs }

    context 'for a puzzle with no clues' do
      it('returns an empty hash') { expect(subject).to eql({}) }
      it('that is froze') { expect(subject).to be_frozen }
    end

    context 'for a puzzle with clues' do
      let(:puzzle) { ad_puzzle }
      it 'shoud return hash of clues keyed by number for #downs' do
        exp = {1 => '1down', 2 => '2down', 3 => '3down', 5 => '5down'}
        expect(subject).to eql(exp)
      end
    end
  end

  describe '#word_count' do
    subject { puzzle.word_count }

    context 'for a puzzle with no clues' do
      it('is 0') { expect(subject).to eql(0) }
    end
    context 'for a puzzle with clues' do
      let(:puzzle) { ad_puzzle }
      it('is the number of clues') { expect(subject).to eql(ad_puzzle_clues.size) }
    end
  end

  describe '#update_word_lengths!' do
    let(:puzzle) { ad_puzzle }
    before { puzzle.send(:update_word_lengths!) }

    context 'for cells without words' do
      let(:cell) { puzzle.cell_at(1, 1) }
      it('has nil for #across_length') { expect(cell.across_length).to be_nil }
      it('has nil for #down_length') { expect(cell.down_length).to be_nil }
    end
    context 'for a cell with a down word' do
      let(:cell) { puzzle.cell_at(2, 1) }
      it('has nil for #across_length') { expect(cell.across_length).to be_nil }
      it('has #down_length set') { expect(cell.down_length).to eql(2) }
    end
    context 'for a cell with an across word' do
      let(:cell) { puzzle.cell_at(0, 1) }
      it('has #across_length set') { expect(cell.across_length).to eql(4) }
      it('has nil for #down_length') { expect(cell.down_length).to be_nil }
    end
    context 'for a cell with an across and down word' do
      let(:cell) { puzzle.cell_at(0, 0) }
      it('has #across_length set') { expect(cell.across_length).to eql(2) }
      it('has #down_length set') { expect(cell.down_length).to eql(3) }
    end
  end

  describe '#convert_to' do
    let(:path) { testfile_path('vanilla.puz') }
    let(:puzzle) { Puzzle.parse_file(path) }
    let(:format) { }

    subject { puzzle.convert_to(format) }

    context 'when format is null' do
      it 'raises an InvalidPuzzleFormat error' do
        expect { subject }.to raise_exception(Crossyglot::InvalidPuzzleFormat)
      end
    end
    context 'for an unknown format' do
      it 'raises an InvalidPuzzleFormat error' do
        expect { subject }.to raise_exception(Crossyglot::InvalidPuzzleFormat)
      end
    end
    context 'for an extension format' do
      let(:format) { 'jpz' }
      it 'converts to an equivalent puzzle of that format' do
        is_expected.to be_kind_of(Crossyglot::Formats::Jpz)
        is_expected.to be_same_puzzle(puzzle)
      end
    end
    context 'for a format class' do
      let(:format) { Crossyglot::Formats::Jpz }
      it 'converts to an equivalent puzzle of that format' do
        is_expected.to be_kind_of(Crossyglot::Formats::Jpz)
        is_expected.to be_same_puzzle(puzzle)
      end
    end
    context 'for the same format as the current class' do
      let(:format) { 'puz' }
      it('returns the same object') { is_expected.to equal(puzzle) }
    end
  end

  describe '#eql?' do
    let(:puzzle_a) { Puzzle.new }
    let(:puzzle_b) { Puzzle.new }
    subject { puzzle_a.eql?(puzzle_b) }

    context 'for empty puzzles' do
      it { is_expected.to be_truthy }
    end
    context 'for puzzles with matching attributes' do
      let(:puzzle_a) do
        Puzzle.new.tap do |p|
          p.author = 'Catfish'
          p.height = p.width = 10
        end
      end
      let(:puzzle_b) do
        Puzzle.new.tap do |p|
          p.author = 'Catfish'
          p.height = p.width = 10
        end
      end
      it { is_expected.to be_truthy }
    end
    context 'for puzzles with mismatched attributes' do
      let(:puzzle_a) do
        Puzzle.new.tap { |p| p.notes = 'Carl' }
      end
      it { is_expected.to be_falsy }
    end
    context 'for puzzles with matching cells' do
      let(:puzzle_a) do
        Puzzle.new.tap do |p|
          p.cells << Cell.new.tap { |c| c.number = 5 }
        end
      end
      let(:puzzle_b) do
        Puzzle.new.tap do |p|
          p.cells << Cell.new.tap { |c| c.number = 5 }
        end
      end
      it { is_expected.to be_truthy }
    end
    context 'for puzzles with different numbers of cells (the first of which match)' do
      let(:puzzle_a) { Puzzle.new.tap { |p| 10.times { p.cells << Cell.new } } }
      let(:puzzle_b) { Puzzle.new.tap { |p| 11.times { p.cells << Cell.new } } }
      it { is_expected.to be_falsy }
    end
    context 'for puzzles with mismatched cells' do
      let(:puzzle_a) { Puzzle.new.tap { |p| p.cells << Cell.new.tap { |c| c.solution = 'a' } } }
      let(:puzzle_b) { Puzzle.new.tap { |p| p.cells << Cell.new.tap { |c| c.solution = 'b' } } }
      it { is_expected.to be_falsy }
    end
  end
end
