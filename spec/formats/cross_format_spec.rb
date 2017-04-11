# encoding: UTF-8
require 'spec_helper'

describe 'Parsing the same puzzle in two separate formats' do
  it 'results in the same puzzle object' do
    puz = Puzzle.parse_file(testfile_path('same.puz'))
    jpz = Puzzle.parse_file(testfile_path('same.jpz'))
    expect(puz).to be_same_puzzle(jpz)
  end
end
