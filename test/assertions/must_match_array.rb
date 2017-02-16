require 'minitest/autorun'

##
# From Justin Ko:
# https://jkotests.wordpress.com/2013/12/02/comparing-arrays-in-an-order-independent-manner-using-minitest/
##
module MiniTest
  module Assertions
    class MatchArray
      def initialize(expected, actual)
        @expected = expected
        @actual = actual
      end

      def match
        [result, message]
      end

      def result
        return false unless @actual.respond_to? :to_ary
        @extra_items = difference_between_arrays(@actual, @expected)
        @missing_items = difference_between_arrays(@expected, @actual)
        @extra_items.empty? & @missing_items.empty?
      end

      def message
        if @actual.respond_to? :to_ary
          message = "expected collection contained: #{safe_sort(@expected).inspect}\n"
          message += "actual collection contained: #{safe_sort(@actual).inspect}\n"
          message += "the missing elements were: #{safe_sort(@missing_items).inspect}\n" unless @missing_items.empty?
          message += "the extra elements were: #{safe_sort(@extra_items).inspect}\n" unless @extra_items.empty?
        else
          message = "expected an array, actual collection was #{@actual.inspect}"
        end

        message
      end

      private

      def safe_sort(array)
        array.sort
      rescue
        array
      end

      def difference_between_arrays(array1, array2)
        difference = array1.to_ary.dup
        array2.to_ary.each do |element|
          index = difference.index(element)
          difference.delete_at(index) if index
        end
        difference
      end
    end # MatchArray

    def assert_match_array(expected, actual)
      result, message = MatchArray.new(expected, actual).match
      assert result, message
    end
  end
end # MiniTest::Assertions

Array.infect_an_assertion :assert_match_array, :must_match_array
