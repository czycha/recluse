require_relative '../lib/recluse/result.rb'
require 'minitest/reporters'
require 'minitest/autorun'

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]

describe Recluse::Result do
  before do
    @codes = {
      blue: [
        Recluse::Result.new(175, nil),
        Recluse::Result.new('idk', nil)
      ],
      green: Recluse::Result.new(200, nil),
      yellow: Recluse::Result.new(301, nil),
      red: [
        Recluse::Result.new(404, nil),
        Recluse::Result.new(500, nil)
      ]
    }
  end
  describe 'colors' do
    it 'should be correct' do
      @codes.each do |color, results|
        [*results].each do |result|
          result.color.must_equal(color)
        end
      end
    end
  end
end
