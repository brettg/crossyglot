# encoding: utf-8
require 'spec_helper'
require 'yaml'

describe Formats::Jpz do
  let(:jpz) {Formats::Jpz.new}

  # make sure a StringIO works w/ unzip

  describe '#parse' do
    %w{zipped unzipped}.each do |jpz_type|
      describe "for a(n) #{jpz_type} file" do
        before(:all) do
          @basic = Formats::Jpz.new.parse_file(testfile_path("basic-#{jpz_type}.jpz"))
        end

        it 'should set #title' do
          @basic.title.should == 'March 24, 2012 - "Movie-Musicals"'
        end

        it 'should set #author' do
          @basic.author.should == 'By Patrick Blindauer'
        end

        it 'should set #copyright' do
          @basic.copyright.should == '© 2012 Patrick Blindauer | CrosSynergy Syndicate LLC'
        end

        it 'should set #height' do
          @basic.height.should == 15
        end

        it 'should set #width' do
          @basic.height.should == 15
        end

        describe 'setting #cells' do
          it 'should add a cell object for each cell' do
            @basic.cells.size.should == 15 * 15
            @basic.cells.each {|c| c.should be_kind_of(Cell)}
          end

          it 'should set cell letters correctly' do
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

            @basic.cells.zip(grid).each do |cell, ltr|
              if ltr == ?.
                cell.should be_black
              else
                cell.solution.should == ltr
              end
            end
          end

          it 'should set the cell numbers correctly' do
            nums = [1, 2, 3, 4, 5, nil, 6, 7, 8, 9, nil, 10, 11, 12, 13,
                    14, nil, nil, nil, nil, nil, 15, nil, nil, nil, nil, 16, nil, nil, nil,
                    17, nil, nil, nil, nil, 18, nil, nil, nil, nil, 19, nil, nil, nil, nil,
                    nil, nil, nil, 20, nil, nil, nil, nil, nil, nil, 21, nil, nil, nil, nil,
                    22, 23, 24, nil, nil, nil, nil, 25, 26, 27, nil, nil, nil, nil, nil,
                    28, nil, nil, nil, nil, nil, 29, nil, nil, nil, nil, 30, nil, nil, nil,
                    31, nil, nil, nil, 32, 33, nil, nil, nil, nil, 34, nil, nil, nil, nil,
                    35, nil, nil, nil, 36, nil, nil, nil, 37, nil, nil, nil, 38, 39, 40,
                    nil, nil, nil, 41, nil, nil, nil, 42, nil, nil, nil, 43, nil, nil, nil,
                    44, 45, 46, nil, nil, 47, nil, nil, nil, nil, nil, 48, nil, nil, nil,
                    49, nil, nil, nil, 50, nil, nil, nil, nil, 51, 52, nil, nil, nil, nil,
                    53, nil, nil, nil, nil, nil, nil, nil, 54, nil, nil, nil, nil, nil, nil,
                    55, nil, nil, nil, nil, 56, 57, 58, nil, nil, nil, nil, 59, 60, 61,
                    62, nil, nil, nil, nil, 63, nil, nil, nil, nil, 64, nil, nil, nil, nil,
                    65, nil, nil, nil, nil, 66, nil, nil, nil, nil, 67, nil, nil, nil, nil]
            @basic.cells.zip(nums).each do |cell, n|
              cell.number.should == n
            end
          end

          it 'should set cell clues correctly' do
            clue_file = File.expand_path('jpz/basic-unzipped-clues.yml', TESTFILE_DIR)
            exp_clues = YAML.load_file(clue_file)
            @basic.acrosses.should == exp_clues['Across']
            @basic.downs.should == exp_clues['Down']
          end
        end
      end
    end
  end
end
