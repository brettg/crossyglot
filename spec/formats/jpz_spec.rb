require 'spec_helper'

describe Formats::Jpz do
  let(:jpz) {Formats::Jpz.new}

  # make sure a StringIO works w/ unzip

  describe '#parse' do
    before(:all) do
      @basic = Formats::Jpz.new.parse_file(testfile_path('basic-unzipped.jpz'))
    end

    it 'should set the title' do
      @basic.title.should == 'March 24, 2012 - "Movie-Musicals"'
    end
  end
end
