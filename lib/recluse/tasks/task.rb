require 'recluse/queue'
require 'recluse/hashtree'

module Recluse
  module Tasks
    ##
    # Task interface. Runs the queue with customized behavior.
    class Task
      ##
      # +HashTree+ representation of results.
      attr_reader :results

      ##
      # +Queue+ of links to check.
      attr_accessor :queue

      ##
      # Create new task.
      def initialize(profile, queue_options: {}, results: nil)
        @queue = Recluse::Queue.new(profile.email, queue_options)
        if results.nil?
          @results = Recluse::HashTree.new do |url1, url2|
            url1, url2 = url2, url1 if url2.length > url1.length
            # Detect if URL exists already, but just has a slash at end
            (url1 == url2 || (url1.length == (url2.length + 1) && url1[-1] == '/' && url2[-1] != '/' && url1[0...-1] == url2))
          end
        else
          @results = results
        end
        @queue.add profile.roots
      end

      ##
      # Add link (or links) to the queue.
      def add(link)
        @queue.add link
      end

      ##
      # Run the queue.
      def run
        @queue.run
      end
    end
  end
end
