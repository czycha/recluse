require 'thor'
require 'safe_yaml'
require 'user_config'

module Recluse
	module CLI
		SafeYAML::OPTIONS[:default_mode] = :safe
		##
		# Whitelist related commands.
		class Whitelist < Thor #:nodoc: all
			desc "add pattern1 [pattern2] ...", "add glob patterns to whitelist"
			def add(name, *patterns)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit(-1)
				end
				profile = uconf["#{name}.yaml"]
				if profile.has_key?('whitelist')
					profile['whitelist'] += patterns
				else
					profile['whitelist'] = patterns
				end
				profile.save
			end
			desc "remove pattern1 [pattern2] ...", "remove patterns from whitelist"
			def remove(name, *patterns)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit(-1)
				end
				profile = uconf["#{name}.yaml"]
				if profile.has_key?('whitelist')
					profile['whitelist'] -= patterns
					profile.save
				end
			end
			desc "clear", "remove all patterns in the whitelist"
			def clear(name)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit(-1)
				end
				profile = uconf["#{name}.yaml"]
				profile['whitelist'] = []
				profile.save
			end
			desc "list", "list patterns in whitelist"
			def list(name)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit(-1)
				end
				profile = uconf["#{name}.yaml"]
				if profile.has_key?('whitelist')
					profile['whitelist'].each { |pattern| puts pattern }
				end
			end
		end
	end
end