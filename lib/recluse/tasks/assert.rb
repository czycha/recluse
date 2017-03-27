require 'recluse/tasks/task'
require 'recluse/link'
require 'recluse/result'
require 'addressable/uri'
require 'colorize'

module Recluse
  module Tasks
    ##
    # Asserts existence of CSS selectors.
    class Assert < Task
      ##
      # Create new assertion task.
      def initialize(profile, selectors: [], quiet: false, results: nil)
        super(profile, queue_options: { redirect: profile.redirect }, results: results)
        addr_roots = profile.roots.map { |root| Addressable::URI.parse(root.url) }
        @queue.run_if do |link|
          internal = link.internal?(addr_roots)
          next false unless link.run?(profile.blacklist, profile.whitelist) && internal && !@results.child?(link.absolute)
          if profile.scheme_squash
            alt = link.address
            alt.scheme = alt.scheme == 'http' ? 'https' : 'http'
            next false if @results.child?(alt.to_s)
          end
          @results.add_child link.absolute
          true
        end
        @queue.on_complete do |link, response|
          existence = nil
          result = Recluse::Result.new response.code.to_s, response.errors
          if response.success
            if profile.redirect
              result_link = Link.new(response.page.uri.to_s, link.parent)
              next unless result_link.internal?(addr_roots)
            end
            unless (response.page.class == Mechanize::File) || (response.page.class == Mechanize::Image)
              existence = {}
              selectors.each do |selector|
                existence[selector] = !response.page.css(selector).empty?
              end
              @results.set_child_value link.absolute, existence
              @queue.add(response.page.links.map { |new_link| Link.new(new_link.uri.to_s, link.absolute) })
            end
          end
          unless quiet
            if result.error != false
              puts "[#{profile.name.colorize(mode: :bold)}][#{result.code.colorize(color: result.color, mode: :bold)}] #{link.absolute}"
              puts "\a^ #{'Error'.colorize(mode: :bold, color: :red)}: #{result.error}"
            elsif !existence.nil?
              existence.each do |selector, exists|
                puts "[#{profile.name.colorize(mode: :bold)}][#{selector.colorize(mode: :bold)}][#{exists.to_s.colorize(color: (exists ? :green : :red), mode: :bold)}] #{link.absolute}"
              end
            end
          end
        end
      end
    end
  end
end
