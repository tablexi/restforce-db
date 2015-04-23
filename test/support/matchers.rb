# https://jkotests.wordpress.com/2013/12/02/comparing-arrays-in-an-order-independent-manner-using-minitest/
module MiniTest

  # :nodoc:
  module Assertions

    # MatchArray performs an order-independent comparison of two arrays.
    class MatchArray

      # :nodoc:
      def initialize(expected, actual)
        @expected = expected
        @actual = actual
      end

      # :nodoc:
      def match
        [result, message]
      end

      # :nodoc:
      def result
        return false unless @actual.respond_to? :to_ary
        @extra_items = diff(@actual, @expected)
        @missing_items = diff(@expected, @actual)
        @extra_items.empty? & @missing_items.empty?
      end

      # :nodoc:
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

      # :nodoc:
      def safe_sort(array)
        array.sort rescue array
      end

      # :nodoc:
      def diff(first, second)
        first.to_ary - second.to_ary
      end

    end

    # Public: Assert that two Arrays are identical, save for the order of their
    # elements.
    #
    # Returns an assertion.
    def assert_match_array(expected, actual)
      result, message = MatchArray.new(expected, actual).match
      assert result, message
    end

  end

  # :nodoc:
  module Expectations

    infect_an_assertion :assert_match_array, :must_match_array

  end

end
