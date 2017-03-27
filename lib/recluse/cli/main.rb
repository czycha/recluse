require 'thor'
require 'recluse/profile'
require 'recluse/statuscode'
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
            report = profile.results[:find].parents
            CSV.open(csv_path, 'w+') do |csv|
              csv << ['Page', 'Matching URLs']
              report.each do |parent, children|
                next if children.empty?
                child_count += children.length
                csv << [parent, children.join("\n")]
                parent_count += 1
              end
            end
          when :none
            report = profile.results[:find].parents
            CSV.open(csv_path, 'w+') do |csv|
              csv << ['Matching URL', 'Page']
              report.each do |parent, children|
                child_count += children.length
                children.each do |child|
                  csv << [child, parent]
                end
                parent_count += 1 unless children.empty?
              end
            end
          when :url
            report = profile.results[:find].children
            CSV.open(csv_path, 'w+') do |csv|
              csv << ['Matching URL', 'Pages']
              parents = Set.new
              report.each do |child, info|
                child_count += 1
                unless info[:parents].empty?
                  csv << [child, info[:parents].join("\n")]
                  parents += info[:parents]
                end
              end
              parent_count = parents.length
            end
          end
          total = profile.results[:find].parents.keys.length
          puts "Total pages:\t#{total}"
          puts "Matched URLs:\t#{child_count}"
          puts "Pages with matches:\t#{parent_count}\t#{perc parent_count, total}%"
        end

        def status_save(profile, csv_path, group_by: :none, includes: [], excludes: [])
          puts 'Saving report...'
          counts = {}
          case group_by
          when :url
            page_label = 'On pages'
            to_csv = proc do |csv, status, child, parents, error|
              csv << [status, child, parents.join("\n"), error || '']
            end
          when :none
            page_label = 'On page'
            to_csv = proc do |csv, status, child, parents, error|
              parents.each do |parent|
                csv << [status, child, parent, error || '']
              end
            end
          end
          valid_status = proc do |code|
            (includes.any? { |include_code| include_code.equal?(code) }) && (excludes.none? { |exclude_code| exclude_code.equal?(code) })
          end
          report = profile.results[:status].children
          CSV.open(csv_path, 'w+') do |csv|
            csv << ['Status code', 'URL', page_label, 'With error']
            report.each do |child, info|
              val = info[:value]
              if val.nil?
                status = 'idk'
                error = 'Incomplete'
              else
                status = val.code
                error = val.error
              end
              if valid_status.call(status)
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
            valid = valid_status.call code
            puts "#{code}:\t#{count.to_i}\t#{perc count, report.length}%\t#{valid ? 'Reported' : 'Unreported'}"
          end
        end

        def assert_save(profile, csv_path, report_vals)
          puts 'Saving report...'
          report = profile.results[:assert].children
          counts = {}
          CSV.open(csv_path, 'w+') do |csv|
            csv << ['Selector', 'Exists', 'On page']
            report.each do |child, info|
              val = info[:value]
              next if val.nil?
              val.each do |selector, exists|
                counts[selector] = { 'true' => 0, 'false' => 0 } unless counts.key? selector
                counts[selector][exists.to_s] += 1
                csv << [selector, exists.to_s, child] if report_vals.include?(exists)
              end
            end
          end
          puts "Total pages:\t#{report.keys.length}"
          counts.each do |selector, _info|
            puts "#{selector}:"
            puts "- True:    #{counts[selector]['true']}\t#{perc counts[selector]['true'], report.keys.length}%"
            puts "- False:   #{counts[selector]['false']}\t#{perc counts[selector]['false'], report.keys.length}%"
            unknown = report.keys.length - counts[selector]['false'] - counts[selector]['true']
            puts "- Unknown: #{unknown}\t#{perc unknown, report.keys.length}%"
          end
        end
      end

      method_option :group_by, type: :string, aliases: '-g', default: 'none', enum: %w(none url), desc: 'Group by key'
      method_option :include, type: :array, aliases: '-i', default: ['xxx'], desc: "Include these status code results. Can be numbers or wildcards (4xx). 'idk' is a Recluse status code for when the status cannot be determined for the page."
      method_option :exclude, type: :array, aliases: '-x', default: [], desc: "Exclude these status code results. Can be numbers or wildcards (4xx). 'idk' is a Recluse status code for when the status cannot be determined for the page."
      desc 'status csv_path profile1 [profile2] ...', 'runs report on link statuses'
      def status(csv_path, *profiles)
        if profiles.empty?
          puts 'No profile provided'
          exit(-1)
        end
        begin
          profile_queue = profiles.map { |profile_name| Recluse::Profile.load profile_name }
        rescue ProfileError => e
          puts e
          exit(-1)
        end
        profile = profile_queue[0]
        if options['group_by'] == 'page'
          puts 'Page grouping only available with --find.'
          exit(-1)
        end
        begin
          includes = options[:include].map { |code| Recluse::StatusCode.new code }
          if includes.empty?
            puts 'No status codes'
            exit(-1)
          end
          excludes = options[:exclude].map { |code| Recluse::StatusCode.new code }
        rescue StatusCodeError => e
          puts e
          exit(-1)
        end
        ending = proc do
          status_save profile, csv_path, group_by: options['group_by'].to_sym, includes: includes, excludes: excludes
          exit
        end
        %w(INT TERM).each do |sig|
          Signal.trap sig, &ending
        end
        (0...profile_queue.length).each do |i|
          profile.results[:status] = profile_queue[i - 1].results[:status] unless i.zero?
          profile.test :status
          profile = profile_queue[i + 1] if i + 1 < profile_queue.length
        end
        %w(INT TERM).each do |sig|
          Signal.trap sig, 'DEFAULT'
        end
        ending.call
      end
      method_option :globs, type: :array, aliases: '-G', required: true, banner: 'GLOB', desc: 'Find links matching any of the globs'
      method_option :group_by, type: :string, aliases: '-g', default: 'none', enum: %w(none url page), desc: 'Group by key'
      desc 'find csv_path profile1 [profile2] ... --globs glob1 [glob2] ...', 'find matching links'
      def find(csv_path, *profiles)
        if profiles.empty?
          puts 'No profile provided'
          exit(-1)
        end
        begin
          profile_queue = profiles.map { |profile_name| Recluse::Profile.load profile_name }
        rescue ProfileError => e
          puts e
          exit(-1)
        end
        profile = profile_queue[0]
        has_globs = options['globs'].any? { |glob| !glob.strip.empty? }
        unless has_globs
          puts 'No glob patterns provided for --globs option'
          exit(-1)
        end
        ending = proc do
          find_save profile, csv_path, group_by: options['group_by'].to_sym
          exit
        end
        %w(INT TERM).each do |sig|
          Signal.trap sig, &ending
        end
        (0...profile_queue.length).each do |i|
          profile.results[:find] = profile_queue[i - 1].results[:find] unless i.zero?
          profile.test(:find, globs: options['globs'])
          profile = profile_queue[i + 1] if i + 1 < profile_queue.length
        end
        %w(INT TERM).each do |sig|
          Signal.trap sig, 'DEFAULT'
        end
        ending.call
      end
      method_option :exists, type: :array, aliases: '-e', required: true, banner: 'SELECTOR', desc: 'Assert existence of HTML elements matching CSS selector'
      method_option :report_true_only, type: :boolean, aliases: '--true', default: false, desc: 'Report only true assertions. Default is to report both true and false.'
      method_option :report_false_only, type: :boolean, aliases: '--false', default: false, desc: 'Report only false assertions. Default is to report both true and false.'
      desc 'assert csv_path profile1 [profile2] ... [options] --exists selector1 [selector2] ...', 'assert HTML element existence'
      def assert(csv_path, *profiles)
        if profiles.empty?
          puts 'No profile provided'
          exit(-1)
        end
        begin
          profile_queue = profiles.map { |profile_name| Recluse::Profile.load profile_name }
        rescue ProfileError => e
          puts e
          exit(-1)
        end
        profile = profile_queue[0]
        has_selectors = options['exists'].any? { |selector| !selector.strip.empty? }
        unless has_selectors
          puts 'No selector patterns provided for --exists option'
          exit(-1)
        end
        report = []
        if options[:report_false_only] == options[:report_true_only]
          report = [true, false]
        elsif options[:report_true_only]
          report = [true]
        elsif option[:report_false_only]
          report = [false]
        end
        ending = proc do
          assert_save profile, csv_path, report
          exit
        end

        %w(INT TERM).each do |sig|
          Signal.trap sig, &ending
        end

        (0...profile_queue.length).each do |i|
          profile.results[:assert] = profile_queue[i - 1].results[:assert] unless i.zero?
          profile.test(:assert, selectors: options['exists'])
          profile = profile_queue[i + 1] if i + 1 < profile_queue.length
        end
        %w(INT TERM).each do |sig|
          Signal.trap sig, 'DEFAULT'
        end
        ending.call
      end
      desc 'where', 'location of profiles'
      def where
        uconf = UserConfig.new '.recluse'
        puts uconf.directory
      end
      desc 'profile [subcommand] [options]', 'profile editor'
      subcommand 'profile', Profile
    end
  end
end
