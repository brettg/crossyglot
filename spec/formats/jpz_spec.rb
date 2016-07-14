# encoding: utf-8
require 'spec_helper'
require 'yaml'
require 'nokogiri'

$_test_jpzs ||= {}
def parse_test_jpz(name)
  $_test_jpzs[name] ||= Formats::Jpz.new.parse_file(testfile_path("#{name}.jpz"))
end

describe Formats::Jpz do
  let(:jpz) { parse_test_jpz('basic-unzipped') }

  describe '#parse' do
    %w{zipped unzipped}.each do |jpz_type|
      describe "for a(n) #{jpz_type} file" do
        subject(:jpz) { parse_test_jpz('basic-' + jpz_type) }

        {title: 'March 24, 2012 - "Movie-Musicals"',
         author: 'By Patrick Blindauer',
         copyright: '© 2012 Patrick Blindauer | CrosSynergy Syndicate LLC',
         height: 15,
         width: 15
        }.each do |attr, val|
          it("sets #{attr}") { expect(subject.public_send(attr)).to eql(val) }
        end

        describe '#cells' do
          subject { super().cells }

          it('is the length of the cells in the puzzle') { expect(subject.size).to eql(15 * 15) }
          it 'and comprised of all Cell objects' do
            subject.each { |c| expect(c).to be_kind_of(Cell) }
          end

          it 'with correctly set letters' do
            grid = "SPATS.JOLT.SOBS
                    ALOHA.ETON.ODIN
                    MYLEFTFOOTLOOSE
                    ...REEF...INUSE
                    BRAISE.TRAVELER
                    BOLT..SOIL.SSTS
                    QUIZSHOWBOAT...
                    SET.TEA.BUD.HBO
                    ...DEARGODSPELL
                    VALE.VERN..LAUD
                    ALLTHERE.CHUTES
                    SPORE...MAIN...
                    SAYANYTHINGGOES
                    ACDC.AKIN.HENNA
                    LAST.MOCK.CROON".gsub(/\s*/, '').split('')

            subject.zip(grid).each do |cell, ltr|
              if ltr == ?.
                expect(cell).to be_black
              else
                expect(cell.solution).to eql(ltr)
              end
            end
          end

          it 'and numbers' do
            nums = [1,   2,   3,   4,   5,   nil, 6,   7,   8,   9,   nil, 10,  11,  12,  13,
                    14,  nil, nil, nil, nil, nil, 15,  nil, nil, nil, nil, 16,  nil, nil, nil,
                    17,  nil, nil, nil, nil, 18,  nil, nil, nil, nil, 19,  nil, nil, nil, nil,
                    nil, nil, nil, 20,  nil, nil, nil, nil, nil, nil, 21,  nil, nil, nil, nil,
                    22,  23,  24,  nil, nil, nil, nil, 25,  26,  27,  nil, nil, nil, nil, nil,
                    28,  nil, nil, nil, nil, nil, 29,  nil, nil, nil, nil, 30,  nil, nil, nil,
                    31,  nil, nil, nil, 32,  33,  nil, nil, nil, nil, 34,  nil, nil, nil, nil,
                    35,  nil, nil, nil, 36,  nil, nil, nil, 37,  nil, nil, nil, 38,  39,  40,
                    nil, nil, nil, 41,  nil, nil, nil, 42,  nil, nil, nil, 43,  nil, nil, nil,
                    44,  45,  46,  nil, nil, 47,  nil, nil, nil, nil, nil, 48,  nil, nil, nil,
                    49,  nil, nil, nil, 50,  nil, nil, nil, nil, 51,  52,  nil, nil, nil, nil,
                    53,  nil, nil, nil, nil, nil, nil, nil, 54,  nil, nil, nil, nil, nil, nil,
                    55,  nil, nil, nil, nil, 56,  57,  58,  nil, nil, nil, nil, 59,  60,  61,
                    62,  nil, nil, nil, nil, 63,  nil, nil, nil, nil, 64,  nil, nil, nil, nil,
                    65,  nil, nil, nil, nil, 66,  nil, nil, nil, nil, 67,  nil, nil, nil, nil]
            subject.zip(nums).each { |cell, n| expect(cell.number).to eql(n) }
          end
        end

        it 'has correclty set clues' do
          clue_file = File.expand_path('jpz/basic-unzipped-clues.yml', TESTFILE_DIR)
          exp_clues = YAML.load_file(clue_file)
          expect(subject.acrosses).to eql(exp_clues['Across'])
          expect(subject.downs).to eql(exp_clues['Down'])
        end
      end
    end
  end

  describe '#write and component methods' do
    it 'writes xml to an IO given an IO' do
      io = StringIO.new
      jpz.write(io)
      xml = io.string
      expect(xml.size).to be > 0
    end
    it 'writes a file to the given a path' do
      tmp_output_path('puzwrite') do |tmp_path|
        jpz.write(tmp_path)
        expect(File.exists?(tmp_path)).to be_truthy
      end
    end

    describe 'the XML output' do
      let(:output_string) { StringIO.new.tap { |io| jpz.write(io) }.string }
      let(:parsed_output) { Nokogiri::XML(output_string) }
      subject { parsed_output }

      def find_subnode(current, name, namespace)
        current.at("ns|#{name}", 'ns' => namespace)
      end
      def contains_node(name, namespace, content_method=nil)
        expect(node = find_subnode(subject, name, namespace)).not_to be_nil
        expect(node.content).to eql(jpz.public_send(content_method))  if content_method
      end

      def self.contains_node(node_name, namespace, content_method=nil, &block)
        it "contains <#{node_name}>" do
          contains_node(node_name, namespace, content_method)
        end

        if block_given?
          describe "<#{node_name}>" do
            subject { find_subnode(super(), node_name, namespace) }
            self.instance_eval(&block)
          end
        end
      end

      contains_node('crossword-compiler-applet', Formats::Jpz::PRIMARY_NAMESPACE) do
        contains_node('rectangular-puzzle', Formats::Jpz::PUZZLE_NAMESPACE) do

          contains_node('metadata', Formats::Jpz::PUZZLE_NAMESPACE) do
            contains_node('creator', Formats::Jpz::PUZZLE_NAMESPACE, :author)
            contains_node('title', Formats::Jpz::PUZZLE_NAMESPACE, :title)
            contains_node('copyright', Formats::Jpz::PUZZLE_NAMESPACE, :copyright)
          end

          contains_node('grid', Formats::Jpz::PUZZLE_NAMESPACE) do
            it('has a width attribute') { expect(subject['width'].to_i).to eql(jpz.width) }
            it('has a height attribute') { expect(subject['height'].to_i).to eql(jpz.height) }

            contains_node('cell', Formats::Jpz::PUZZLE_NAMESPACE)
          end
        end
      end

      context 'the <cell> nodes' do
        subject { super().css('ns|grid > ns|cell', ns: Formats::Jpz::PUZZLE_NAMESPACE) }
        it('has one for each cell') { expect(subject.count).to eql(jpz.width * jpz.height) }

        context 'for a numbered cell' do
          # <cell x="2" y="10" solution="A" number="45"></cell>
          subject { super().at('[x="2"][y="10"]') }

          it('includes a solution attribute') { expect(subject['solution']).to eql('A') }
          it('includes a number attribute') { expect(subject['number']).to eql('45') }
          it('does not include a type attribute') { expect(subject['type']).to be_nil }
        end
        context 'for a black cell' do
          # <cell x="2" y="4" type="block"></cell>
          subject { super().at('[x="2"][y="4"]') }

          it('does not include a solution attribute') { expect(subject['solution']).to be_nil }
          it('does not include a number attribute') { expect(subject['number']).to be_nil }
          it('includes a type attribute') { expect(subject['type']).to eql('block') }
        end
      end

    end
  end
end
