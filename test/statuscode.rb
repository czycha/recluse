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
      Recluse::StatusCode.new(200)
                         .exact?
                         .must_equal(true)
      Recluse::StatusCode.new('2xx')
                         .exact?
                         .must_equal(false)
      Recluse::StatusCode.new('idk')
                         .exact?
                         .must_equal(true)
    end
  end
  describe 'when comparing status codes' do
    it 'should work between exact codes' do
      Recluse::StatusCode.new(300)
                         .equal?(300)
                         .must_equal(true)
      Recluse::StatusCode.new(300)
                         .equal?('300')
                         .must_equal(true)
      Recluse::StatusCode.new(500)
                         .equal?(300)
                         .must_equal(false)
      Recluse::StatusCode.new('idk')
                         .equal?('idk')
                         .must_equal(true)
      Recluse::StatusCode.new('idk')
                         .equal?(300)
                         .must_equal(false)
    end
    it 'should work between exact and inexact codes' do
      Recluse::StatusCode.new(300)
                         .equal?('3xx')
                         .must_equal(true)
      Recluse::StatusCode.new(300)
                         .equal?('4xx')
                         .must_equal(false)
      Recluse::StatusCode.new(300)
                         .equal?('xxx')
                         .must_equal(true)
      Recluse::StatusCode.new('idk')
                         .equal?('xxx')
                         .must_equal(true)
    end
    it 'should work between inexact codes' do
      Recluse::StatusCode.new('3xx')
                         .equal?('3xx')
                         .must_equal(true)
      Recluse::StatusCode.new('x0x')
                         .equal?('40x')
                         .must_equal(true)
      Recluse::StatusCode.new('3xx')
                         .equal?('xxx')
                         .must_equal(true)
      Recluse::StatusCode.new('3xx')
                         .equal?('4xx')
                         .must_equal(false)
    end
  end
end
