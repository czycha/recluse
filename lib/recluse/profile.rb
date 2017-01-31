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
			@name = name
			@email = email
			if roots.length >= 1
				@roots = roots
			else
				raise ProfileError.new("Profile needs roots for starting point")
			end
			@blacklist = blacklist
			@whitelist = whitelist
			@internal_only = internal_only
			@scheme_squash = scheme_squash
			@redirect = redirect
			@results = HashTree.new
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
		def status quiet: false
			queue = @roots.map { |url| Link.new(url, :root) }
			addrroot = @roots.map { |url| Addressable::URI.parse url }
			raise ProfileError.new("No roots to start from") if queue.length < 1
			agent = create_agent
			while queue.length >= 1
				element = queue.shift
				next unless element.run?(@blacklist, @whitelist) 
				internal = element.internal?(addrroot)
				next if @internal_only and not internal
				if @results.child?(element.absolute)
					@results.add element.absolute, element.parent
					next
				else
					@results.add element.absolute, element.parent
					if @scheme_squash
						alt = element.address
						if alt.scheme == "http"
							alt.scheme = "https"
						else
							alt.scheme = "http"
						end
						if @results.child?(alt.to_s)
							@results.set_child_value element.absolute, @results.get_child_value(alt.to_s)
							next
						end
					end
				end
				result = Result.new "idk", false
				begin
					page = agent.get element.absolute
					result.code = page.code
					if @redirect
						result_link = Link.new(page.uri.to_s, element.parent)
						internal = result_link.internal?(addrroot)
					end
					queue += page.links.map { |link| Link.new(link.uri.to_s, element.absolute) } if internal and page.class != Mechanize::File and page.class != Mechanize::Image
				rescue Mechanize::ResponseCodeError => code
					result.code = code.response_code
				rescue => e
					result.error = e
				end
				@results.set_child_value element.absolute, result
				unless quiet
					puts "[#{@name.colorize(:mode => :bold)}][#{result.code.colorize(:color => result.color, :mode => :bold)}][#{(internal ? 'internal' : 'external').colorize(:mode => :bold)}] #{element.absolute}"
					puts "\a^ #{"Error".colorize(:mode => :bold, :color => :red)}: #{result.error}" unless result.error == false
				end
			end
		end

		##
		# Find links matching glob patterns, starting from the roots. Overrides (but does not overwrite) +internal_only+ behavior to +true+.
		def find glob, quiet: false
			queue = @roots.map { |url| Link.new(url, :root) }
			addrroot = @roots.map { |url| Addressable::URI.parse url }
			raise ProfileError.new("No roots to start from") if queue.length < 1
			progress = ProgressBar.create(total: nil, format: "|%B|") unless quiet
			agent = create_agent
			while queue.length >= 1
				element = queue.shift
				match = element.match? glob
				if match
					@results.add element.absolute, element.parent
					progress.log "[#{@name.colorize(:mode => :bold)}][#{"found".colorize(:color => :green, :mode => :bold)}] #{element.parent} => #{element.absolute}" unless quiet
				end
				next unless element.run?(@blacklist, @whitelist) 
				internal = element.internal?(addrroot)
				next if not internal
				if @results.parent?(element.absolute)
					next
				else
					if @scheme_squash
						alt = element.address
						if alt.scheme == "http"
							alt.scheme = "https"
						else
							alt.scheme = "http"
						end
						if @results.parent?(alt.to_s)
							next
						end
					end
				end
				@results.add_parent element.absolute
				result = Result.new "idk", false
				begin
					page = agent.get element.absolute
					result.code = page.code
					if @redirect
						result_link = Link.new(page.uri.to_s, element.parent)
						next unless result_link.internal?(addroot)
					end
					queue += page.links.map { |link| Link.new(link.uri.to_s, element.absolute) } unless page.class == Mechanize::File or page.class == Mechanize::Image
				rescue Mechanize::ResponseCodeError => code
					result.code = code.response_code
				rescue => e
					result.error = e
				end
				progress.increment unless quiet
				unless quiet or result.error == false
					progress.log "[#{@name.colorize(:mode => :bold)}][#{result.code.colorize(:color => result.color, :mode => :bold)}] #{element.absolute}"
					progress.log "\a^ #{"Error".colorize(:mode => :bold, :color => :red)}: #{result.error}"
				end
			end
		end

		##
		# Asserts existence of CSS selectors.
		def assert selectors, quiet: false
			queue = @roots.map { |url| Link.new(url, :root) }
			addrroot = @roots.map { |url| Addressable::URI.parse url }
			raise ProfileError.new("No roots to start from") if queue.length < 1
			agent = create_agent
			while queue.length >= 1
				element = queue.shift
				internal = element.internal?(addrroot)
				next unless element.run?(@blacklist, @whitelist) and internal
				if @results.child?(element.absolute)
					next
				else
					if @scheme_squash
						alt = element.address
						if alt.scheme == "http"
							alt.scheme = "https"
						else
							alt.scheme = "http"
						end
						if @results.child?(alt.to_s)
							next
						end
					end
				end
				@results.add_child element.absolute
				existence = nil
				result = Result.new "idk", false
				begin
					page = agent.get element.absolute
					result.code = page.code
					if @redirect
						result_link = Link.new(page.uri.to_s, element.parent)
						next unless result_link.internal?(addroot)
					end
					unless page.class == Mechanize::File or page.class == Mechanize::Image
						existence = {}
						selectors.each do |selector|
							existence[selector] = page.css(selector).length > 0
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
						puts "[#{@name.colorize(:mode => :bold)}][#{result.code.colorize(:color => result.color, :mode => :bold)}] #{element.absolute}"
						puts "\a^ #{"Error".colorize(:mode => :bold, :color => :red)}: #{result.error}"
					else
						unless existence.nil?
							existence.each do |selector, exists|
								puts "[#{@name.colorize(:mode => :bold)}][#{selector.colorize(:mode => :bold)}][#{exists.to_s.colorize(:color => (exists ? :green : :red), :mode => :bold)}] #{element.absolute}"
							end
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
			options.save
		end

		##
		# Loads profile by name.
		def self.load(profile)
			uconf = UserConfig.new '.recluse'
			raise ProfileError.new("Profile '#{profile}' doesn't exist") unless uconf.exist?("#{profile}.yaml")
			options = uconf["#{profile}.yaml"]
			expects = [:blacklist, :whitelist, :internal_only, :scheme_squash, :redirect]
			opts = {}
			for e in expects
				estr = e.to_s
				opts[e] = options[estr] if options.key?(estr) and not options[estr].nil?
			end
			ret = Profile.new(
				profile, 
				((options.key?('roots') and not options['roots'].nil?) ? options['roots'] : []),
				((options.key?('email') and not options['email'].nil?) ? options['email'] : ''),
				**opts
			)
			return ret
		end
	end
end