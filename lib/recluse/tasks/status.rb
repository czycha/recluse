require 'recluse/tasks/task'
require 'recluse/link'
require 'recluse/result'
require 'addressable/uri'
require 'colorize'

module Recluse
  module Tasks
    ##
    # Starting from the roots, goes through each runnable link and records the referrer, the status code, and any errors.
    class Status < Task
      ##
      # Create new status task.
      def initialize(profile, quiet: false, results: nil)
        super(profile, queue_options: { redirect: profile.redirect }, results: results)
        addr_roots = profile.roots.map { |root| Addressable::URI.parse(root.url) }
        @queue.run_if do |link|
          next false unless link.run?(profile.blacklist, profile.whitelist)
          internal = link.internal?(addr_roots)
          next false if profile.internal_only && !internal
          if @results.child?(link.absolute)
            @results.add link.absolute, link.parent
            next false
          end
          @results.add link.absolute, link.parent
          if profile.scheme_squash
            alt = link.address
            alt.scheme = alt.scheme == 'http' ? 'https' : 'http'
            if @results.child?(alt.to_s)
              @results.set_child_value link.absolute, @results.get_child_value(alt.to_s)
              next false
            end
          end
          true
        end
        @queue.on_complete do |link, response|
          result = Recluse::Result.new response.code.to_s, response.errors
          if response.success
            internal = link.internal? addr_roots
            if profile.redirect
              result_link = Recluse::Link.new response.page.uri.to_s, link.parent
              internal = result_link.internal? addr_roots
            end
            queue.add(response.page.links.map { |new_link| Link.new(new_link.uri.to_s, link.absolute) }) if internal && (response.page.class != Mechanize::File) && (response.page.class != Mechanize::Image)
          end
          @results.set_child_value link.absolute, result
          unless quiet
            puts "[#{profile.name.colorize(mode: :bold)}][#{result.code.colorize(color: result.color, mode: :bold)}][#{(internal ? 'internal' : 'external').colorize(mode: :bold)}] #{link.absolute}"
            puts "\a^ #{'Error'.colorize(mode: :bold, color: :red)}: #{result.error}" unless result.error == false
          end
        end
      end
    end
  end
end
