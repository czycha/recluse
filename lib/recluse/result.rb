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

		##
		# Color based on code.
		def color
			case (@code.to_i / 100)
			when 2
				color = :green
			when 3
				color = :yellow
			when 4, 5
				color = :red
			else
				color = :blue
			end
			color
		end
	end
end