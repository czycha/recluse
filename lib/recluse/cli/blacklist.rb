require 'thor'
require 'safe_yaml'
require 'user_config'

module Recluse
	module CLI
		SafeYAML::OPTIONS[:default_mode] = :safe
		class Blacklist < Thor
			desc "add pattern1 [pattern2] ...", "add glob patterns to blacklist"
			def add(name, *patterns)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit -1
				end
				profile = uconf["#{name}.yaml"]
				if profile.has_key?('blacklist')
					profile['blacklist'] += patterns
				else
					profile['blacklist'] = patterns
				end
				profile.save
			end
			desc "remove pattern1 [pattern2] ...", "remove glob patterns from blacklist"
			def remove(name, *patterns)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit -1
				end
				profile = uconf["#{name}.yaml"]
				if profile.has_key?('blacklist')
					profile['blacklist'] -= patterns
					profile.save
				end
			end
			desc "clear", "remove all patterns in the blacklist"
			def clear(name)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit -1
				end
				profile = uconf["#{name}.yaml"]
				profile['blacklist'] = []
				profile.save
			end
			desc "list", "list patterns in blacklist"
			def list(name)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit -1
				end
				profile = uconf["#{name}.yaml"]
				if profile.has_key?('blacklist')
					profile['blacklist'].each { |pattern| puts pattern }
				end
			end
		end
	end
end