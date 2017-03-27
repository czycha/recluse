require 'addressable/uri'

module Recluse
  ##
  # Errors related to links.
  class LinkError < RuntimeError
  end

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
      raise LinkError, 'Incorrect parent URL. Expects :root or a string.' unless parent == :root || parent.class == String
      @url = url
      @parent = parent
      @address = @parent == :root ? Addressable::URI.parse(@url) : Addressable::URI.join(@parent, @url)
      @address.fragment = nil
      @absolute = @address.to_s
    end

    ##
    # Output as string.
    def to_s
      @absolute
    end

    ##
    # Inspection
    def inspect
      to_s
    end

    ##
    # Is the link internal compared to +Addressable::URI+ roots?
    def internal?(addrroots, scheme_squash: false)
      return true if @parent == :root
      return addrroots.any? { |root| Link.internal_to?(root, @address) } unless scheme_squash
      a2 = @address.dup
      a2.scheme = a2.scheme == 'https' ? 'http' : 'https'
      addrroots.any? { |root| (Link.internal_to?(root, @address) || Link.internal_to?(root, a2)) }
    end

    ##
    # Is the link runnable compared to the black- and whitelists, and the link scheme?
    def run?(blacklist, whitelist)
      ((@address.scheme == 'http') || (@address.scheme == 'https')) && (!match?(blacklist) || match?(whitelist))
    end

    ##
    # Does the link match any of the globs?
    def match?(globs)
      [*globs].any? { |glob| File.fnmatch(glob, @absolute) }
    end

    ##
    # Check if +to+ is internal compared to +root+. Building block of +internal?+. Both +root+ and +to+ must be of type +Addressable::URI+.
    #
    # A link is internal compared to the root if it matches the following conditions:
    #
    # - Same scheme, subdomain, and domain. In other words, a relative URL can be built out of the link.
    # - If +root+ is a directory and doesn't contain a filename (e.g. +http://example.com/test/+):
    #   - Internal if link is below the root's path or is the same (e.g. +http://example.com/test/index.php+).
    # - Otherwise if +root+ contains a filename (e.g. +http://example.com/test/index.php+):
    #   - Internal if link is below parent directory of root (e.g. +http://example.com/test/about.php+).
    def self.internal_to?(root, to)
      route = root.route_to(to)
      return false if route == to # can't be represented as relative url
      route_internal = route.to_s[0...3] != '../'
      has_slash = root.path[-1] == '/'
      return route_internal if has_slash || !root.extname.empty?
      slashed_root = root.dup
      slashed_root.path = "#{root.path}/"
      slashed_route = slashed_root.route_to(to)
      (slashed_route.to_s[0...3] != '../')
    end
  end
end
