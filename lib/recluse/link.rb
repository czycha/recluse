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
				return addrroots.none? { |root| (root.route_to(@address) == @address and root.route_to(a2) == a2) }
			else
				return addrroots.none? { |root| root.route_to(@address) == @address }
			end
		end

		##
		# Is the link runnable compared to the black- and whitelists, and the link scheme? 
		def run?(blacklist, whitelist)
			return false unless @address.scheme == 'http' or @address.scheme == 'https'
			return not match?(blacklist) or match?(whitelist)
		end

		##
		# Does the link match any of the globs?
		def match?(globs)
			[*globs].any? { |glob| File.fnmatch(glob, @absolute) }
		end
	end
end