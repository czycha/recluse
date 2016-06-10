module Recluse
	##
	# Very simple result container.
	class Result
		##
		# HTTP status code.
		attr_accessor :code

		##
		# Access error message.
		attr_accessor :error

		##
		# Create a result.
		def initialize(code, error)
			@code = code
			@error = error
		end

		##
		# Returns the HTTP status code.
		def inspect
			@code
		end
	end
end