module Recluse
  ##
  # Error to throw if there's something non-standard with the status code.
  class StatusCodeError < RuntimeError
  end

  ##
  # An HTTP status code.
  class StatusCode
    ##
    # The status code. Either a number, a string with x's to represent wildcards, or 'idk'.
    attr_reader :code

    ##
    # Whether or not this is an exact numerical code.
    attr_reader :exact

    ##
    # Create a status code.
    def initialize(code)
      raise StatusCodeError, "Invalid status code: #{code}" unless StatusCode.valid_code?(code)
      case code
      when String
        if (code =~ /^[\d]{3}/).nil? # wildcards
          @code = code.downcase
          @exact = false
        else # whole number
          @code = code.to_i
          @exact = true
        end
      when Recluse::StatusCode
        @code = code.code
        @exact = code.exact
      when Integer
        @code = code
        @exact = true
      end
    end

    ##
    # Output the status code to a string.
    def to_s
      @code.to_s
    end

    ##
    # Whether or not this is an exact numerical code.
    def exact?
      @exact
    end

    ##
    # Is this code equal to another?
    def equal?(other)
      comparable = StatusCode.new other
      return @code == comparable.code if exact? && comparable.exact?
      self_s = to_s
      comparable_s = comparable.to_s
      (0...3).all? do |i|
        StatusCode.equal_digit?(self_s[i], comparable_s[i])
      end
    end

    ##
    # Is the passed code valid?
    def self.valid_code?(code)
      case code
      when String
        code = code.downcase
        return false if (code =~ /^([\dx]{3}|idk)$/i).nil?
        return true if (code == 'idk') || (code[0] == 'x')
        initial = code[0].to_i
        ((1 <= initial) && (initial <= 5))
      when Integer
        ((100 <= code) && code < 600)
      when Recluse::StatusCode
        true
      else
        false
      end
    end

    class << self
      ##
      # Digital comparison. x's are wildcards.
      def equal_digit?(a, b)
        ((a == b) || (a == 'x') || (b == 'x'))
      end
    end
  end
end
