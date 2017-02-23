require 'recluse/hashtree'
require 'recluse/link'
require 'recluse/result'
require 'recluse/info'
require 'addressable/uri'
require 'mechanize'
require 'colorize'
require 'user_config'
require 'ruby-progressbar'

module Recluse
  ##
  # Error to throw if there's something non-standard with the profile configuration.
  class ProfileError < RuntimeError
  end

  ##
  # A profile is an atomic unit of rules for link checking.
  class Profile
    ##
    # Identifier of the profile. Make sure that it is filename friendly. Required.
    attr_accessor :name

    ##
    # Array of URLs to start spidering. Required.
    attr_accessor :roots

    ##
    # Used in the user-agent to identify who is running the crawler. This is so that if there's a problem with your spidering, you will be contacted and not the author of Recluse. Required.
    attr_accessor :email

    ##
    # Array of URL patterns to check. Optional. Defaults to empty array.
    attr_accessor :blacklist

    ##
    # Array of exceptions to the blacklist. Optional. Defaults to empty array.
    attr_accessor :whitelist

    ##
    # Don't check external URLs. Optional. Defaults to +false+.
    attr_accessor :internal_only

    ##
    # HTTP and HTTPS schemed URLs are treated as equal. Optional. Defaults to +false+.
    attr_accessor :scheme_squash

    ##
    # +HashTree+ representation of results.
    attr_accessor :results

    ##
    # When enabled, will follow redirects and report only the status code for the page that is landed upon. When disabled, will report the redirect status code. Defaults to +false+.
    attr_accessor :redirect

    ##
    # Create a profile.
    def initialize(
        name,
        roots,
        email,
        blacklist: [],
        whitelist: [],
        internal_only: false,
        scheme_squash: false,
        redirect: false
    )
      raise ProfileError, 'Profile needs roots for starting point' if roots.empty?
      @name = name
      @email = email
      @roots = roots
      @blacklist = blacklist
      @whitelist = whitelist
      @internal_only = internal_only
      @scheme_squash = scheme_squash
      @redirect = redirect
      @results = HashTree.new do |url1, url2|
        url1, url2 = url2, url1 if url2.length > url1.length
        # Detect if URL exists already, but just has a slash at end
        (url1 == url2 || (url1.length == (url2.length + 1) && url1[-1] == '/' && url2[-1] != '/' && url1[0...-1] == url2))
      end
    end

    ##
    # Create a +Mechanize+ agent.
    def create_agent
      Mechanize.new do |a|
        a.ssl_version = 'TLSv1'
        a.verify_mode = OpenSSL::SSL::VERIFY_NONE
        a.max_history = nil
        a.follow_meta_refresh = true
        a.keep_alive = false
        a.redirect_ok = @redirect
        a.user_agent = "Mozilla/5.0 (compatible; recluse/#{Recluse::VERSION}; +#{Recluse::URL}) #{@email}"
      end
    end

    ##
    # Starting from the roots, goes through each runnable link and records the referrer, the status code, and any errors.
    # Results are saved in <tt>@results</tt>.
    def status(quiet: false)
      queue = @roots.map { |url| Link.new(url, :root) }
      addrroot = @roots.map { |url| Addressable::URI.parse url }
      raise ProfileError, 'No roots to start from' if queue.empty?
      agent = create_agent
      while queue.length >= 1
        element = queue.shift
        next unless element.run?(@blacklist, @whitelist)
        internal = element.internal?(addrroot)
        next if @internal_only && !internal
        if @results.child?(element.absolute)
          @results.add element.absolute, element.parent
          next
        end
        @results.add element.absolute, element.parent
        if @scheme_squash
          alt = element.address
          alt.scheme = alt.scheme == 'http' ? 'https' : 'http'
          if @results.child?(alt.to_s)
            @results.set_child_value element.absolute, @results.get_child_value(alt.to_s)
            next
          end
        end
        result = Result.new 'idk', false
        begin
          page = agent.get element.absolute
          result.code = page.code
          if @redirect
            result_link = Link.new(page.uri.to_s, element.parent)
            internal = result_link.internal?(addrroot)
          end
          queue += page.links.map { |link| Link.new(link.uri.to_s, element.absolute) } if internal && (page.class != Mechanize::File) && (page.class != Mechanize::Image)
        rescue Mechanize::ResponseCodeError => code
          result.code = code.response_code
        rescue => e
          result.error = e
        end
        @results.set_child_value element.absolute, result
        unless quiet
          puts "[#{@name.colorize(mode: :bold)}][#{result.code.colorize(color: result.color, mode: :bold)}][#{(internal ? 'internal' : 'external').colorize(mode: :bold)}] #{element.absolute}"
          puts "\a^ #{'Error'.colorize(mode: :bold, color: :red)}: #{result.error}" unless result.error == false
        end
      end
    end

    ##
    # Find links matching glob patterns, starting from the roots. Overrides (but does not overwrite) +internal_only+ behavior to +true+.
    def find(glob, quiet: false)
      queue = @roots.map { |url| Link.new(url, :root) }
      addrroot = @roots.map { |url| Addressable::URI.parse url }
      raise ProfileError, 'No roots to start from' if queue.empty?
      progress = ProgressBar.create(total: nil, format: '|%B|') unless quiet
      agent = create_agent
      while queue.length >= 1
        element = queue.shift
        match = element.match? glob
        if match
          @results.add element.absolute, element.parent
          progress.log "[#{@name.colorize(mode: :bold)}][#{'found'.colorize(color: :green, mode: :bold)}] #{element.parent} => #{element.absolute}" unless quiet
        end
        next unless element.run?(@blacklist, @whitelist)
        internal = element.internal?(addrroot)
        next unless internal
        next if @results.parent?(element.absolute)
        if @scheme_squash
          alt = element.address
          alt.scheme = alt.scheme == 'http' ? 'https' : 'http'
          next if @results.parent?(alt.to_s)
        end
        @results.add_parent element.absolute
        result = Result.new 'idk', false
        begin
          page = agent.get element.absolute
          result.code = page.code
          if @redirect
            result_link = Link.new(page.uri.to_s, element.parent)
            next unless result_link.internal?(addrroot)
          end
          queue += page.links.map { |link| Link.new(link.uri.to_s, element.absolute) } unless (page.class == Mechanize::File) || (page.class == Mechanize::Image)
        rescue Mechanize::ResponseCodeError => code
          result.code = code.response_code
        rescue => e
          result.error = e
        end
        progress.increment unless quiet
        unless quiet || (result.error == false)
          progress.log "[#{@name.colorize(mode: :bold)}][#{result.code.colorize(color: result.color, mode: :bold)}] #{element.absolute}"
          progress.log "\a^ #{'Error'.colorize(mode: :bold, color: :red)}: #{result.error}"
        end
      end
    end

    ##
    # Asserts existence of CSS selectors.
    def assert(selectors, quiet: false)
      queue = @roots.map { |url| Link.new(url, :root) }
      addrroot = @roots.map { |url| Addressable::URI.parse url }
      raise ProfileError, 'No roots to start from' if queue.empty?
      agent = create_agent
      while queue.length >= 1
        element = queue.shift
        internal = element.internal?(addrroot)
        next unless element.run?(@blacklist, @whitelist) && internal && !@results.child?(element.absolute)
        if @scheme_squash
          alt = element.address
          alt.scheme = alt.scheme == 'http' ? 'https' : 'http'
          next if @results.child?(alt.to_s)
        end
        @results.add_child element.absolute
        existence = nil
        result = Result.new 'idk', false
        begin
          page = agent.get element.absolute
          result.code = page.code
          if @redirect
            result_link = Link.new(page.uri.to_s, element.parent)
            next unless result_link.internal?(addrroot)
          end
          unless (page.class == Mechanize::File) || (page.class == Mechanize::Image)
            existence = {}
            selectors.each do |selector|
              existence[selector] = !page.css(selector).empty?
            end
            @results.set_child_value element.absolute, existence
            queue += page.links.map { |link| Link.new(link.uri.to_s, element.absolute) }
          end
        rescue Mechanize::ResponseCodeError => code
          result.code = code.response_code
        rescue => e
          result.error = e
        end
        unless quiet
          if result.error != false
            puts "[#{@name.colorize(mode: :bold)}][#{result.code.colorize(color: result.color, mode: :bold)}] #{element.absolute}"
            puts "\a^ #{'Error'.colorize(mode: :bold, color: :red)}: #{result.error}"
          elsif !existence.nil?
            existence.each do |selector, exists|
              puts "[#{@name.colorize(mode: :bold)}][#{selector.colorize(mode: :bold)}][#{exists.to_s.colorize(color: (exists ? :green : :red), mode: :bold)}] #{element.absolute}"
            end
          end
        end
      end
    end

    ##
    # Saves profile to <tt>~/.recluse/NAME.yaml</tt>.
    def save
      uconf = UserConfig.new '.recluse'
      fname = "#{@name}.yaml"
      options = uconf[fname]
      options['name'] = @name
      options['roots'] = @roots
      options['email'] = @email
      options['blacklist'] = @blacklist
      options['whitelist'] = @whitelist
      options['internal_only'] = @internal_only
      options['scheme_squash'] = @scheme_squash
      options['redirect'] = @redirect
      options.save
    end

    ##
    # Test if profiles share the same configuration options.
    def ==(other)
      return false if other.class != self.class
      instance_variables.all? do |ivar|
        ivar == '@results'.to_sym || instance_variable_get(ivar) == other.instance_variable_get(ivar)
      end
    end

    ##
    # Loads profile by name.
    def self.load(profile)
      uconf = UserConfig.new '.recluse'
      raise ProfileError, "Profile '#{profile}' doesn't exist" unless uconf.exist?("#{profile}.yaml")
      options = uconf["#{profile}.yaml"]
      expects = [:blacklist, :whitelist, :internal_only, :scheme_squash, :redirect]
      opts = {}
      expects.each do |e|
        estr = e.to_s
        opts[e] = options[estr] if options.key?(estr) && !options[estr].nil?
      end
      ret = Profile.new(
        profile,
        (options.key?('roots') && !options['roots'].nil? ? options['roots'] : []),
        (options.key?('email') && !options['email'].nil? ? options['email'] : ''),
        **opts
      )
      ret
    end
  end
end
