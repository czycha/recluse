require 'recluse/hashtree'
require 'recluse/link'
require 'recluse/result'
require 'recluse/info'
require 'recluse/tasks/list'
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
    # When enabled, will follow redirects and report only the status code for the page that is landed upon. When disabled, will report the redirect status code. Defaults to +false+.
    attr_accessor :redirect

    ##
    # The list of run tests.
    attr_accessor :tasks

    ##
    # Hash of resulting +HashTree+s.
    attr_accessor :results

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
      @roots = roots.map do |root|
        if root.class == Link
          root
        else
          Link.new(root, :root)
        end
      end
      @blacklist = blacklist
      @whitelist = whitelist
      @internal_only = internal_only
      @scheme_squash = scheme_squash
      @redirect = redirect
      @tasks = {}
      @results = {}
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
    # Runs test.
    def test(key, options = {})
      unless @results.key?(key) && @results[key].class == Recluse::HashTree
        @results[key] = Recluse::HashTree.new do |url1, url2|
          url1, url2 = url2, url1 if url2.length > url1.length
          # Detect if URL exists already, but just has a slash at end
          (url1 == url2 || (url1.length == (url2.length + 1) && url1[-1] == '/' && url2[-1] != '/' && url1[0...-1] == url2))
        end
      end
      @tasks[key] = Recluse::Tasks.get(key).new(self, options.merge(results: @results[key]))
      @tasks[key].run
      @results[key]
    end

    ##
    # Saves profile to <tt>~/.recluse/NAME.yaml</tt>.
    def save
      uconf = UserConfig.new '.recluse'
      fname = "#{@name}.yaml"
      options = uconf[fname]
      options['name'] = @name
      options['roots'] = @roots.map(&:to_s)
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
        next true if ivar == '@results'.to_sym
        next true if ivar == '@roots' && instance_variable_get(ivar).map(&:to_s) == other.instance_variable_get(ivar).map(&:to_s)
        instance_variable_get(ivar) == other.instance_variable_get(ivar)
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
