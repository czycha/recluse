require 'recluse/tasks/status'
require 'recluse/tasks/assert'
require 'recluse/tasks/find'

module Recluse
  ##
  # Tasks are tests for Recluse.
  module Tasks
    ##
    # Hash of available tasks.
    @@list = {
      status: Recluse::Tasks::Status,
      assert: Recluse::Tasks::Assert,
      find: Recluse::Tasks::Find
    }
    class << self
      ##
      # Add task to the list.
      def add_task(key, task_class)
        list[key] = task_class
      end

      ##
      # Hash of available tasks.
      def list
        @@list
      end

      ##
      # Get task by key name.
      def get(key)
        @@list[key]
      end

      ##
      # Do something for each task.
      def each(&block)
        @@list.each(&block)
      end
    end
  end
end
