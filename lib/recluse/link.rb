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

		##
		# Check if +to+ is internal compared to +root+. Building block of +internal?+.
		#
		# A link is internal compared to the root if it matches the following conditions:
		#
		# - Same scheme, subdomain, and domain. In other words, a relative URL can be built out of the link.
		# - If +root+ is a directory and doesn't contain a filename (e.g. +http://example.com/test/+):
		#    - Internal if link is below the root's path or is the same (e.g. +http://example.com/test/index.php+).
		# - Otherwise +root+ contains a filename (e.g. +http://example.com/test/index.php+):
		#    - Internal if link is below parent directory of root (e.g. +http://example.com/test/about.php+).
		def self.internal_to?(root, to)
			route = root.route_to(to)
			if route == to # can't be represented as relative url
				return false
			else
				route_internal = route.to_s[0...3] != "../"
				has_slash = root.path[-1] == "/"
				if not has_slash # could be a file, or it could be a directory without a slash
					is_file = !root.extname.empty?
					if is_file
						return route_internal
					else
						slashed_root = root.dup
						slashed_root.path = "#{root.path}/"
						slashed_route = slashed_root.route_to(to)
						return (slashed_route.to_s[0...3] != "../")
					end
				else
					return route_internal
				end
			end
		end
	end
end