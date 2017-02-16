require_relative '../lib/recluse/hashtree.rb'
require_relative './assertions/must_match_array.rb'
require 'minitest/reporters'
require 'minitest/autorun'

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]

describe Recluse::HashTree do
  before do
    @legend = {
      'A' => 0,
      'B' => 1,
      'C' => 2,
      'D' => 3,
      'E' => 4
    }
    @hashes = Array.new(3) { Recluse::HashTree.new }
    # Complex network
    @hashes[0].add('A', 'B')
    @hashes[0].add('B', 'C')
    @hashes[0].add('C', 'D')
    @hashes[0].add('D', 'A')
    @hashes[0].add('E', 'E')
    @hashes[0].add('E', 'A')
    @hashes[0].add('E', 'B')
    @legend.each do |k, v|
      @hashes[0].set_child_value(k, v)
    end
    # No parents
    @hashes[1].add_child('A')
    @hashes[1].add_child('B')
    @hashes[1].add_child('C')
    @hashes[1].add_child('D')
    @hashes[1].add_child('E')
    @legend.each do |k, v|
      @hashes[1].set_child_value(k, v)
    end
    # No children
    @hashes[2].add_parent('A')
    @hashes[2].add_parent('B')
    @hashes[2].add_parent('C')
    @hashes[2].add_parent('D')
    @hashes[2].add_parent('E')
  end
  describe 'children' do
    it 'should be able to get values' do
      (0..1).each do |i|
        @legend.each do |k, v|
          @hashes[i].get_child_value(k)
                    .must_equal(v)
        end
      end
    end
    it 'should be able to return parents' do
      @hashes[0].get_parents('A')
                .must_match_array(['B'])
      @hashes[0].get_parents('E')
                .must_match_array(%w(A B E))
      @hashes[1].get_parents('A')
                .must_match_array([])
    end
    it 'should be returnable' do
      @hashes[0].children
                .keys
                .must_match_array(@legend.keys)
      @hashes[1].children
                .keys
                .must_match_array(@legend.keys)
      @hashes[2].children
                .keys
                .must_match_array([])
    end
    it 'should be detectable' do
      @hashes[0].child?('A')
                .must_equal(true)
      @hashes[1].child?('A')
                .must_equal(true)
      @hashes[2].child?('A')
                .must_equal(false)
    end
    it 'can be orphans' do
      @hashes[0].orphans
                .keys
                .must_match_array([])
      @hashes[1].orphans
                .keys
                .must_match_array(@legend.keys)
      @hashes[2].orphans
                .keys
                .must_match_array([])
    end
  end
  describe 'parents' do
    it 'should be able to return children' do
      @hashes[0].get_children('A')
                .must_match_array(%w(D E))
      @hashes[0].get_children('E')
                .must_match_array(['E'])
      @hashes[2].get_children('A')
                .must_match_array([])
    end
    it 'should be returnable' do
      @hashes[0].parents
                .keys
                .must_match_array(@legend.keys)
      @hashes[1].parents
                .keys
                .must_match_array([])
      @hashes[2].parents
                .keys
                .must_match_array(@legend.keys)
    end
    it 'should be detectable' do
      @hashes[0].parent?('A')
                .must_equal(true)
      @hashes[1].parent?('A')
                .must_equal(false)
      @hashes[2].parent?('A')
                .must_equal(true)
    end
    it 'can be childless' do
      @hashes[0].childless
                .keys
                .must_match_array([])
      @hashes[1].childless
                .keys
                .must_match_array([])
      @hashes[2].childless
                .keys
                .must_match_array(@legend.keys)
    end
    it 'should be able to get values' do
      @hashes[0].get_values('A')
                .must_equal(@legend.select { |k, v| k == 'E' || k == 'D' })
      @hashes[2].get_values('A')
                .must_equal({})
    end
  end
  it 'should be able to detect either child or parent' do
    @hashes[0].has?('A')
              .must_equal(true)
    @hashes[1].has?('A')
              .must_equal(true)
    @hashes[2].has?('A')
              .must_equal(true)
  end
  describe 'deletion' do
    it 'should be able to delete children' do
      @hashes[0].delete_child('A')
      @hashes[0].child?('A')
                .must_equal(false)
      @hashes[1].delete_child('A')
      @hashes[1].child?('A')
                .must_equal(false)
    end
    it 'should be able to delete parents' do
      @hashes[0].delete_parent('B')
      @hashes[0].parent?('B')
                .must_equal(false)
      @hashes[2].delete_parent('B')
      @hashes[2].parent?('B')
                .must_equal(false)
    end
    it 'should be able to delete dual-roled elements' do
      @hashes[0].delete('E')
      @hashes[0].has?('E')
                .must_equal(false)
      @hashes[1].delete('E')
      @hashes[1].has?('E')
                .must_equal(false)
      @hashes[2].delete('E')
      @hashes[2].has?('E')
                .must_equal(false)
    end
  end
end
