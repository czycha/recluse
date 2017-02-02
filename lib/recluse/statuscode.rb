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
			raise StatusCodeError.new("Invalid status code: #{code}") unless StatusCode.valid_code?(code)
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
			when Fixnum
				@code = code
				@exact = true
			end
		end

		##
		# Output the status code to a string.
		def to_s
			return @code.to_s
		end

		##
		# Whether or not this is an exact numerical code.
		def exact?
			return @exact
		end

		##
		# Is this code equal to another?
		def equal?(comparable_code)
			comparable = StatusCode.new comparable_code
			if exact? and comparable.exact?
				return @code == comparable.code
			else
				self_s = to_s
				comparable_s = comparable.to_s
				for i in (0...3)
					return false unless StatusCode.equal_digit?(self_s[i], comparable_s[i])
				end
				return true
			end
		end

		##
		# Is the passed code valid?
		def self.valid_code?(code)
			case code
			when String
				if (code =~ /^([\dx]{3}|idk)$/i).nil?
					return false
				else
					code = code.downcase
					if code == 'idk' or code[0] == 'x'
						return true
					else
						initial = code[0].to_i
						return (1 <= initial and initial <= 5)
					end
				end
			when Fixnum
				return (100 <= code and code < 600)
			when Recluse::StatusCode
				return true
			else
				return false
			end
		end

		private

		##
		# Digital comparison. x's are wildcards.
		def self.equal_digit?(a, b)
			return (a == b or a == 'x' or b == 'x')
		end
	end
end