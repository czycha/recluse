require 'recluse/tasks/task'
require 'recluse/link'
require 'recluse/result'
require 'addressable/uri'
require 'colorize'
require 'ruby-progressbar'

module Recluse
  module Tasks
    ##
    # Find links matching glob patterns, starting from the roots. Overrides (but does not overwrite) +internal_only+ behavior to +true+.
    class Find < Task
      ##
      # Create new find task.
      def initialize(profile, globs: [], quiet: false, results: nil)
        super(profile, queue_options: { redirect: profile.redirect }, results: results)
        addr_roots = profile.roots.map { |root| Addressable::URI.parse(root.url) }
        progress = ProgressBar.create(total: nil, format: '|%B|') unless quiet
        @queue.run_if do |link|
          match = link.match? globs
          if match
            @results.add link.absolute, link.parent
            progress.log "[#{profile.name.colorize(mode: :bold)}][#{'found'.colorize(color: :green, mode: :bold)}] #{link.parent} => #{link.absolute}" unless quiet
          end
          next false unless link.run?(profile.blacklist, profile.whitelist)
          internal = link.internal?(addr_roots)
          next false unless internal
          next false if @results.parent?(link.absolute)
          if profile.scheme_squash
            alt = link.address
            alt.scheme = alt.scheme == 'http' ? 'https' : 'http'
            next false if @results.parent?(alt.to_s)
          end
          @results.add_parent link.absolute
          true
        end
        @queue.on_complete do |link, response|
          result = Recluse::Result.new response.code.to_s, response.errors
          if response.success
            if profile.redirect
              result_link = Recluse::Link.new(response.page.uri.to_s, link.parent)
              next unless result_link.internal?(addr_roots)
            end
            @queue.add(response.page.links.map { |new_link| Link.new(new_link.uri.to_s, link.absolute) }) unless (response.page.class == Mechanize::File) || (response.page.class == Mechanize::Image)
          end
          progress.increment unless quiet
          unless quiet || (result.error == false)
            progress.log "[#{profile.name.colorize(mode: :bold)}][#{result.code.colorize(color: result.color, mode: :bold)}] #{link.absolute}"
            progress.log "\a^ #{'Error'.colorize(mode: :bold, color: :red)}: #{result.error}"
          end
        end
      end
    end
  end
end
