require 'thor'
require 'recluse/profile'
require 'recluse/cli/whitelist'
require 'recluse/cli/blacklist'
require 'recluse/cli/roots'
require 'user_config'

module Recluse
	module CLI
		##
		# Commands to edit/create/delete profiles.
		class Profile < Thor #:nodoc: all
			method_option :blacklist, :type => :array, :desc => "Glob patterns for URLs to ignore", :default => []
			method_option :whitelist, :type => :array, :desc => "Glob pattern exceptions to blacklist", :default => []
			method_option :internal_only, :type => :boolean, :desc => "Only check internal URLs", :default => false
			method_option :scheme_squash, :type => :boolean, :desc => "HTTP and HTTPS URLs are treated as equals", :default => false
			method_option :redirect, :type => :boolean, :desc => "Follow redirects and report final status code", :default => false
			desc "create [options] name email root1 [root2] ...", "create profile"
			def create(name, email, *roots)
				uconf = UserConfig.new '.recluse'
				if uconf.exist?("#{name}.yaml")
					puts "Profile #{name} already exists"
					exit(-1)
				end
				begin
					profile = Recluse::Profile.new(
						name, 
						roots, 
						email,
						blacklist: options["blacklist"],
						whitelist: options["whitelist"],
						internal_only: options["internal_only"],
						scheme_squash: options["scheme_squash"],
						redirect: options["redirect"]
					)
					profile.save
				rescue ProfileError => e
					puts e
					exit(-1)
				end
			end
			desc "profile remove name", "remove profile"
			def remove(name)
				uconf = UserConfig.new '.recluse'
				if uconf.exist?("#{name}.yaml")
					uconf.delete "#{name}.yaml"
				else
					exit(-1)
				end
			end
			method_option :blacklist, :type => :array, :desc => "Glob patterns for URLs to ignore"
			method_option :whitelist, :type => :array, :desc => "Glob pattern exceptions to blacklist"
			method_option :internal_only, :type => :boolean, :desc => "Only check internal URLs"
			method_option :scheme_squash, :type => :boolean, :desc => "HTTP and HTTPS URLs are treated as equals"
			method_option :roots, :type => :array, :desc => "Roots to start the spidering at"
			method_option :email, :type => :string, :desc => "Email to identify spider for system admins"
			method_option :redirect, :type => :boolean, :desc => "Follow redirects and report final status code"
			desc "edit name [options]", "edit profile"
			def edit(name)
				begin
					profile = Recluse::Profile.load name
				rescue ProfileError => e
					puts e
					exit(-1)
				end
				profile.roots = options["roots"] if options.key? "roots"
				profile.blacklist = options["blacklist"] if options.key? "blacklist"
				profile.whitelist = options["whitelist"] if options.key? "whitelist"
				profile.internal_only = options["internal_only"] if options.key? "internal_only"
				profile.scheme_squash = options["scheme_squash"] if options.key? "scheme_squash"
				profile.redirect = options["redirect"] if options.key? "redirect"
				profile.email = options["email"] if options.key? "email"
				profile.save
			end
			desc "rename old_name new_name", "rename profile"
			def rename(old_name, new_name)
				uconf = UserConfig.new '.recluse'
				if uconf.exist?("#{new_name}.yaml")
					puts "Profile #{new_name} already exists"
					exit(-1)
				end
				if uconf.exist?("#{old_name}.yaml")
					old_profile = uconf["#{old_name}.yaml"]
					old_profile['name'] = new_name
					new_profile = uconf["#{new_name}.yaml"]
					old_profile.each do |key, value|
						new_profile[key] = value
					end
					new_profile.save
					uconf.delete "#{old_name}.yaml"
				end
			end
			desc "list", "list profiles"
			def list
				uconf = UserConfig.new '.recluse'
				files = uconf.list_in_directory '.'
				for file in files
					puts file.gsub(/\.yaml$/, "")
				end
			end
			desc "info name", "profile information"
			def info(name)
				uconf = UserConfig.new '.recluse'
				unless uconf.exist?("#{name}.yaml")
					puts "Profile #{name} doesn't exist"
					exit(-1)
				end
				puts uconf["#{name}.yaml"].to_yaml
			end
			desc "blacklist [subcommand] [options]", "edit blacklist"
			subcommand "blacklist", Blacklist
			desc "roots [subcommand] [options]", "edit roots"
			subcommand "roots", Roots
			desc "whitelist [subcommand] [options]", "edit whitelist"
			subcommand "whitelist", Whitelist
		end
	end
end