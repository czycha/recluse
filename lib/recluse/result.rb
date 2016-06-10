module Recluse
	class Result
		attr_accessor :code, :error
		def initialize(code, error)
			@code = code
			@error = error
		end
		def inspect
			@code
		end
	end
end