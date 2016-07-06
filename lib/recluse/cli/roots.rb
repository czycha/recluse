require 'thor'
require 'safe_yaml'
require 'user_config'

module Recluse
	module CLI
		SafeYAML::OPTIONS[:default_mode] = :safe
		##
		# Roots related commands.
		class Roots < Thor #:nodoc: all
			desc "add profile pattern1 [pattern2] ...", "add to roots"
			def add(name, *roots)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit(-1)
				end
				profile = uconf["#{name}.yaml"]
				if profile.key?('roots')
					profile['roots'] += roots
				else
					profile['roots'] = roots
				end
				profile.save
			end
			desc "remove profile pattern1 [pattern2] ...", "remove from roots"
			def remove(name, *roots)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit(-1)
				end
				profile = uconf["#{name}.yaml"]
				if profile.key?('roots')
					profile['roots'] -= roots
					profile.save
				end
			end
			desc "list profile", "list roots"
			def list(name)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit(-1)
				end
				profile = uconf["#{name}.yaml"]
				if profile.key?('roots')
					profile['roots'].each { |root| puts root }
				end
			end
		end
	end
end