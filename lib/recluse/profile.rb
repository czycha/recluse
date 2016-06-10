require 'safe_yaml'
require 'recluse/weirdtree'
require 'recluse/link'
require 'recluse/result'
require 'recluse/info'
require 'addressable/uri'
require 'mechanize'
require 'colorize'
require 'user_config'

module Recluse
	class ProfileError < RuntimeError
	end
	class Profile
		attr_accessor :name, :roots, :email, :blacklist, :whitelist, :internal_only, :scheme_squash, :results
		def initialize(
				name, 
				roots,
				email,
				blacklist: [], 
				whitelist: [], 
				internal_only: false,
				scheme_squash: false
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
			@results = WeirdTree.new
		end
		def create_agent
			Mechanize.new do |a| 
				a.ssl_version = 'TLSv1'
				a.verify_mode = OpenSSL::SSL::VERIFY_NONE
				a.max_history = nil
				a.follow_meta_refresh = true
				a.keep_alive = false
				a.user_agent = "Mozilla/5.0 (compatible; recluse/#{Recluse::VERSION}; +#{Recluse::URL}) #{@email}"
			end
		end
		def run
			queue = @roots.map { |url| Link.new(url, :root) }
			addrroot = @roots.map { |url| Addressable::URI.parse url }
			raise ProfileError.new("No roots to start from") if queue.length < 1
			agent = create_agent
			while queue.length >= 1
				element = queue.shift
				next unless element.run?(@blacklist, @whitelist) 
				internal = element.internal?(addrroot)
				next if @internal_only and not internal
				if @results.has_child?(element.absolute)
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
						if @results.has_child?(alt.to_s)
							@results.set_child_value element.absolute, @results.get_child_value(alt.to_s)
							next
						end
					end
				end
				result = Result.new "idk", false
				begin
					page = agent.get element.absolute
					result.code = page.code
					queue += page.links.map { |link| Link.new(link.uri.to_s, element.absolute) } if internal and page.class != Mechanize::File
				rescue Mechanize::ResponseCodeError => code
					result.code = code.response_code
				rescue => e
					result.error = e
				end
				@results.set_child_value element.absolute, result
				case (result.code.to_i / 100)
				when 2
					color = :green
				when 3
					color = :yellow
				when 4, 5
					color = :red
				else
					color = :blue
				end
				puts "[#{@name.colorize(:mode => :bold)}][#{result.code.colorize(:color => color, :mode => :bold)}][#{(internal ? 'internal' : 'external').colorize(:mode => :bold)}] #{element.absolute}"
				puts "\a^ #{"Error".colorize(:mode => :bold, :color => :red)}: #{result.error}" unless result.error == false
			end
		end
		def find glob
			queue = @roots.map { |url| Link.new(url, :root) }
			addrroot = @roots.map { |url| Addressable::URI.parse url }
			raise ProfileError.new("No roots to start from") if queue.length < 1
			agent = create_agent
			while queue.length >= 1
				element = queue.shift
				match = element.match? glob
				if match
					@results.add element.absolute, element.parent
					puts "[#{@name.colorize(:mode => :bold)}][#{"found".colorize(:color => :green, :mode => :bold)}] #{element.parent} => #{element.absolute}"
				end
				next unless element.run?(@blacklist, @whitelist) 
				internal = element.internal?(addrroot)
				next if not internal
				if @results.has_parent?(element.absolute)
					next
				else
					if @scheme_squash
						alt = element.address
						if alt.scheme == "http"
							alt.scheme = "https"
						else
							alt.scheme = "http"
						end
						if @results.has_parent?(alt.to_s)
							next
						end
					end
				end
				@results.add_parent element.absolute
				result = Result.new "idk", false
				begin
					page = agent.get element.absolute
					result.code = page.code
					queue += page.links.map { |link| Link.new(link.uri.to_s, element.absolute) } unless page.class == Mechanize::File
				rescue Mechanize::ResponseCodeError => code
					result.code = code.response_code
				rescue => e
					result.error = e
				end
				case (result.code.to_i / 100)
				when 2
					color = :green
				when 3
					color = :yellow
				when 4, 5
					color = :red
				else
					color = :blue
				end
				unless result.error == false
					puts "[#{@name.colorize(:mode => :bold)}][#{result.code.colorize(:color => color, :mode => :bold)}] #{element.absolute}"
					puts "\a^ #{"Error".colorize(:mode => :bold, :color => :red)}: #{result.error}"
				end
			end
		end
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
		def self.load(profile)
			SafeYAML::OPTIONS[:default_mode] = :safe
			uconf = UserConfig.new '.recluse'
			raise ProfileError.new("Profile '#{profile}' doesn't exist") unless uconf.exist?("#{profile}.yaml")
			options = uconf["#{profile}.yaml"]
			expects = [:blacklist, :whitelist, :internal_only, :scheme_squash]
			opts = {}
			for e in expects
				estr = e.to_s
				opts[e] = options[estr] if options.has_key?(estr) and not options[estr].nil?
			end
			ret = Profile.new(
				profile, 
				((options.has_key?('roots') and not options['roots'].nil?) ? options['roots'] : []),
				((options.has_key?('email') and not options['email'].nil?) ? options['email'] : ''),
				**opts
			)
			return ret
		end
	end
end