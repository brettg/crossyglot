# encoding: utf-8
require 'spec_helper'

describe Formats::Jpz do
  let(:jpz) {Formats::Jpz.new}

  # make sure a StringIO works w/ unzip

  describe '#parse' do
    before(:all) do
      @basic = Formats::Jpz.new.parse_file(testfile_path('basic-unzipped.jpz'))
    end

    it 'should set title' do
      @basic.title.should == 'March 24, 2012 - "Movie-Musicals"'
    end

    it 'should set author' do
      @basic.author.should == 'By Patrick Blindauer'
    end

    it 'should set copyright' do
      @basic.copyright.should == '© 2012 Patrick Blindauer | CrosSynergy Syndicate LLC'
    end

    it 'should set height' do
      @basic.height.should == 15
    end

    it 'should set width' do
      @basic.height.should == 15
    end
  end
end
