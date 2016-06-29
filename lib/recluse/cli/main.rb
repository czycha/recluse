require 'thor'
require 'recluse/profile'
require 'recluse/cli/profile'
require 'csv'
require 'user_config'

module Recluse
	##
	# Command-line interface segments.
	module CLI
		##
		# Main commands.
		class Main < Thor #:nodoc: all
			no_commands do
				def perc(num, den)
					(num * 100.0 / den).round(2)
				end
				def save(profile, csv_path, find: false)
					puts "Saving report..."
					if find
						report = profile.results.parents
						child_count = 0
						parent_count = 0
						CSV.open(csv_path, "w+") do |csv|
							csv << ["Page", "Matching URLs"]
							report.each do |parent, children|
								child_count += children.length
								unless children.length == 0
									csv << [parent, children.join("\n")]
									parent_count += 1
								end
							end
						end
						puts "Total pages:\t#{report.keys.length}"
						puts "Matched URLs:\t#{child_count}"
						puts "Pages with matches:\t#{parent_count}\t#{perc parent_count, report.keys.length}%"
					else
						counts = {}
						report = profile.results.children
						CSV.open(csv_path, "w+") do |csv|
							csv << ["Status code", "URL", "On pages", "With error"]
							report.each do |child, info|
								val = info[:value]
								if val.nil?
									status = "idk"
									error = "Uncomplete"
								else
									status = val.code
									error = val.error
								end
								unless (status.to_i / 100) == 2
									csv << [status, child, info[:parents].join("\n"), error || ""]
								end
								if counts.has_key?(status)
									counts[status] += 1.0
								else
									counts[status] = 1.0
								end
							end
						end
						puts "Total:\t#{report.length}"
						counts.each do |code, count|
							puts "#{code}:\t#{count.to_i}\t#{perc count, report.length}%"
						end
					end
				end
			end
			method_option :find, :type => :array, :aliases => "-f", :banner => "GLOB", :desc => "Find links matching any of the globs"
			desc "report csv_path profile1 [profile2] ...", "runs profile report"
			def report(csv_path, *profiles)
				if profiles.length == 0
					puts "No profile provided"
					exit(-1)
				end
				begin
					profile_queue = profiles.map { |profile_name| Recluse::Profile.load profile_name }
				rescue ProfileError => e
					puts e
					exit(-1)
				end
				profile = profile_queue[0]
				Signal.trap 'INT' do
					save profile, csv_path, find: options.has_key?("find")
					exit
				end
				Signal.trap 'TERM' do
					save profile, csv_path, find: options.has_key?("find")
					exit
				end
				if options.has_key?("find")
					has_globs = options["find"].any? { |glob| glob.strip.length > 0 }
					unless has_globs
						Signal.trap 'INT', 'DEFAULT'
						Signal.trap 'TERM', 'DEFAULT'
						puts "No glob patterns provided for --find option"
						exit(-1)
					end
					for i in 0...profile_queue.length
						profile.results = profile_queue[i - 1].results unless i == 0
						profile.find options["find"]
						profile = profile_queue[i + 1] if i + 1 < profile_queue.length
					end
				else
					for i in 0...profile_queue.length
						profile.results = profile_queue[i - 1].results unless i == 0
						profile.run
						profile = profile_queue[i + 1] if i + 1 < profile_queue.length
					end
				end
				Signal.trap 'INT', 'DEFAULT'
				Signal.trap 'TERM', 'DEFAULT'
				save profile, csv_path, find: options.has_key?("find")
			end
			desc "where", "location of profiles"
			def where
				uconf = UserConfig.new ".recluse"
				puts uconf.directory
			end
			desc "profile [subcommand] [options]", "profile editor"
			subcommand "profile", Profile
		end
	end
end