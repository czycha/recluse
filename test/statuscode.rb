require_relative '../lib/recluse/statuscode.rb'
require 'minitest/reporters'
require 'minitest/autorun'

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]

describe Recluse::StatusCode do
  describe 'when creating new status code' do
    it 'should support duplicating another code' do
      first = Recluse::StatusCode.new 200
      Recluse::StatusCode.new(first)
                         .code
                         .must_equal(first.code)
    end
    it 'should convert exact numeric strings into integers' do
      Recluse::StatusCode.new('200')
                         .code
                         .must_equal(200)
    end
    it 'should respect detect exact vs inexact codes' do
      assert Recluse::StatusCode.new(200).exact?
      refute Recluse::StatusCode.new('2xx').exact?
      assert Recluse::StatusCode.new('idk').exact?
    end
  end
  describe 'when comparing status codes' do
    it 'should work between exact codes' do
      assert Recluse::StatusCode.new(300).equal?(300)
      assert Recluse::StatusCode.new(300).equal?('300')
      refute Recluse::StatusCode.new(500).equal?(300)
      assert Recluse::StatusCode.new('idk').equal?('idk')
      refute Recluse::StatusCode.new('idk').equal?(300)
    end
    it 'should work between exact and inexact codes' do
      assert Recluse::StatusCode.new(300).equal?('3xx')
      refute Recluse::StatusCode.new(300).equal?('4xx')
      assert Recluse::StatusCode.new(300).equal?('xxx')
      assert Recluse::StatusCode.new('idk').equal?('xxx')
    end
    it 'should work between inexact codes' do
      assert Recluse::StatusCode.new('3xx').equal?('3xx')
      assert Recluse::StatusCode.new('x0x').equal?('40x')
      assert Recluse::StatusCode.new('3xx').equal?('xxx')
      refute Recluse::StatusCode.new('3xx').equal?('4xx')
    end
  end
end
