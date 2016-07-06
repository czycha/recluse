require 'addressable/uri'

module Recluse
	##
	# A simple link container for a profile's queue.
	class Link
		##
		# URL of link. Can be relative.
		attr_reader :url

		##
		# Parent of link (i.e. the referrer). Can be +:root+ if no parent.
		attr_reader :parent

		##
		# The absolute URL of the link.
		attr_reader :absolute

		##
		# The +Addressable::URI+ representation of the link.
		attr_reader :address

		##
		# Create a link.
		def initialize(url, parent)
			@url = url
			@parent = parent
			if @parent == :root
				@address = Addressable::URI.parse @url
			else
				@address = Addressable::URI.join @parent, @url
			end
			@address.fragment = nil
			@absolute = @address.to_s
		end

		##
		# Is the link internal compared to +Addressable::URI+ roots?
		def internal?(addrroots, scheme_squash: false)
			return true if @parent == :root
			if scheme_squash
				a2 = @address.dupe
				if a2.scheme == "https"
					a2.scheme = "http"
				else
					a2.scheme = "https"
				end
				return addrroots.any? { |root| (Link.internal_to?(root, @address) or Link.internal_to?(root, a2)) }
			else
				return addrroots.any? { |root| Link.internal_to?(root, @address) }
			end
		end

		##
		# Is the link runnable compared to the black- and whitelists, and the link scheme? 
		def run?(blacklist, whitelist)
			return false unless @address.scheme == 'http' or @address.scheme == 'https'
			return (not match?(blacklist) or match?(whitelist))
		end

		##
		# Does the link match any of the globs?
		def match?(globs)
			[*globs].any? { |glob| File.fnmatch(glob, @absolute) }
		end

		private

		##
		# Check if +to+ is internal compared to +root+. Building block of +internal?+.
		def self.internal_to?(root, to)
			route = root.route_to(to)
			if route == to # completely different URL
				return false
			else
				route_internal = route.to_s[0...3] != "../"
				root_slash = root.path[-1] == "/"
				if root_slash and route_internal
					return true
				else
					alt_root = root.dup
					if not root_slash
						alt_root.path = "#{root.path}/"
					else
						alt_root.path = root.path[0...-1]
					end
					alt_route = alt_root.route_to(to)
					alt_internal = alt_route.to_s[0...3] != "../"
					return ((root_slash or route_internal) and alt_internal)
				end
			end
		end
	end
end