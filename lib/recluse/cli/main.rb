require 'thor'
require 'recluse/profile'
require 'recluse/cli/profile'
require 'csv'
require 'user_config'
require 'set'

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
				def find_save(profile, csv_path, group_by: :none)
					puts "\nSaving report..."
					child_count = 0
					parent_count = 0
					case group_by
					when :page
						report = profile.results.parents
						CSV.open(csv_path, "w+") do |csv|
							csv << ["Page", "Matching URLs"]
							report.each do |parent, children|
								unless children.length == 0
									child_count += children.length
									csv << [parent, children.join("\n")]
									parent_count += 1
								end
							end
						end
					when :none
						report = profile.results.parents
						CSV.open(csv_path, "w+") do |csv|
							csv << ["Matching URL", "Page"]
							report.each do |parent, children|
								child_count += children.length
								children.each do |child|
									csv << [child, parent]
								end
								parent_count += 1 if children.length > 0
							end
						end
					when :url
						report = profile.results.children
						CSV.open(csv_path, "w+") do |csv|
							csv << ["Matching URL", "Pages"]
							parents = Set.new
							report.each do |child, info|
								child_count += 1
								unless info[:parents].length == 0
									csv << [child, info[:parents].join("\n")]
									parents += info[:parents]
								end
							end
							parent_count = parents.length
						end
					end
					total = profile.results.parents.keys.length
					puts "Total pages:\t#{total}"
					puts "Matched URLs:\t#{child_count}"
					puts "Pages with matches:\t#{parent_count}\t#{perc parent_count, total}%"
				end
				def status_save(profile, csv_path, group_by: :none)
					puts "Saving report..."
					counts = {}
					case group_by
					when :url
						page_label = "On pages"
						to_csv = Proc.new do |csv, status, child, parents, error|
							csv << [status, child, parents.join("\n"), error || ""]
						end
					when :none
						page_label = "On page"
						to_csv = Proc.new do |csv, status, child, parents, error|
							parents.each do |parent|
								csv << [status, child, parent, error || ""]
							end
						end
					end
					report = profile.results.children
					CSV.open(csv_path, "w+") do |csv|
						csv << ["Status code", "URL", page_label, "With error"]
						report.each do |child, info|
							val = info[:value]
							if val.nil?
								status = "idk"
								error = "Incomplete"
							else
								status = val.code
								error = val.error
							end
							unless (status.to_i / 100) == 2
								to_csv.call(csv, status, child, info[:parents], error)
							end
							if counts.key?(status)
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
				def assert_save(profile, csv_path)
					puts "Saving report..."
					report = profile.results.children
					counts = {}
					CSV.open(csv_path, "w+") do |csv|
						csv << ["Selector", "Exists", "On page"]
						report.each do |child, info|
							val = info[:value]
							unless val.nil?
								val.each do |selector, exists|
									counts[selector] = {"true" => 0, "false" => 0} unless counts.key? selector
									counts[selector][exists.to_s] += 1
									csv << [selector, exists.to_s, child]
								end
							end
						end
					end
					puts "Total pages:\t#{report.keys.length}"
					counts.each do |selector, info|
						puts "#{selector}:"
						puts "- True:    #{counts[selector]["true"]}\t#{perc counts[selector]["true"], report.keys.length}%"
						puts "- False:   #{counts[selector]["false"]}\t#{perc counts[selector]["false"], report.keys.length}%"
						unknown = report.keys.length - counts[selector]["false"] - counts[selector]["true"]
						puts "- Unknown: #{unknown}\t#{perc (unknown), report.keys.length}%"
					end
				end
			end
			method_option :group_by, :type => :string, :aliases => "-g", :default => "none", :enum => ["none", "url"], :desc => "Group by key"
			desc "status csv_path profile1 [profile2] ...", "runs report on link statuses"
			def status(csv_path, *profiles)
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
				if options["group_by"] == "page"
					puts "Page grouping only available with --find."
					exit -1
				end
				ending = Proc.new do
					status_save profile, csv_path, group_by: options["group_by"].to_sym
					exit
				end
				for sig in ['INT', 'TERM']
					Signal.trap sig, &ending
				end
				for i in 0...profile_queue.length
					profile.results = profile_queue[i - 1].results unless i == 0
					profile.status
					profile = profile_queue[i + 1] if i + 1 < profile_queue.length
				end
				for sig in ['INT', 'TERM']
					Signal.trap sig, 'DEFAULT'
				end
				ending.call
			end
			method_option :globs, :type => :array, :aliases => "-G", :required => true, :banner => "GLOB", :desc => "Find links matching any of the globs"
			method_option :group_by, :type => :string, :aliases => "-g", :default => "none", :enum => ["none", "url", "page"], :desc => "Group by key"
			desc "find csv_path profile1 [profile2] ... --globs glob1 [glob2] ...", "find matching links"
			def find(csv_path, *profiles)
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
				has_globs = options["globs"].any? { |glob| glob.strip.length > 0 }
				unless has_globs
					puts "No glob patterns provided for --globs option"
					exit(-1)
				end
				ending = Proc.new do
					find_save profile, csv_path, group_by: options["group_by"].to_sym
					exit
				end
				for sig in ['INT', 'TERM']
					Signal.trap sig, &ending
				end
				for i in 0...profile_queue.length
					profile.results = profile_queue[i - 1].results unless i == 0
					profile.find options["globs"]
					profile = profile_queue[i + 1] if i + 1 < profile_queue.length
				end
				for sig in ['INT', 'TERM']
					Signal.trap sig, 'DEFAULT'
				end
				ending.call
			end
			method_option :exists, :type => :array, :aliases => "-e", :required => true, :banner => "SELECTOR", :desc => "Assert existence of HTML elements matching CSS selector"
			desc "assert csv_path profile1 [profile2] ... --exists selector1 [selector2] ...", "assert HTML element existence"
			def assert(csv_path, *profiles)
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
				has_selectors = options["exists"].any? { |selector| selector.strip.length > 0 }
				unless has_selectors
					puts "No selector patterns provided for --exists option"
					exit(-1)
				end
				ending = Proc.new do
					assert_save profile, csv_path
					exit
				end
				for sig in ['INT', 'TERM']
					Signal.trap sig, &ending
				end
				for i in 0...profile_queue.length
					profile.results = profile_queue[i - 1].results unless i == 0
					profile.assert options["exists"]
					profile = profile_queue[i + 1] if i + 1 < profile_queue.length
				end
				for sig in ['INT', 'TERM']
					Signal.trap sig, 'DEFAULT'
				end
				ending.call
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