require 'thor'
require 'user_config'

module Recluse
  module CLI
    ##
    # Blacklist related commands.
    class Blacklist < Thor #:nodoc: all
      desc 'add profile pattern1 [pattern2] ...', 'add glob patterns to blacklist'
      def add(name, *patterns)
        uconf = UserConfig.new '.recluse'
        unless uconf.exist?("#{name}.yaml")
          puts "Profile #{name} doesn't exist"
          exit(-1)
        end
        profile = uconf["#{name}.yaml"]
        if profile.key?('blacklist')
          profile['blacklist'] += patterns
        else
          profile['blacklist'] = patterns
        end
        profile.save
      end
      desc 'remove profile pattern1 [pattern2] ...', 'remove glob patterns from blacklist'
      def remove(name, *patterns)
        uconf = UserConfig.new '.recluse'
        unless uconf.exist?("#{name}.yaml")
          puts "Profile #{name} doesn't exist"
          exit(-1)
        end
        profile = uconf["#{name}.yaml"]
        return unless profile.key?('blacklist')
        profile['blacklist'] -= patterns
        profile.save
      end
      desc 'clear profile', 'remove all patterns in the blacklist'
      def clear(name)
        uconf = UserConfig.new '.recluse'
        unless uconf.exist?("#{name}.yaml")
          puts "Profile #{name} doesn't exist"
          exit(-1)
        end
        profile = uconf["#{name}.yaml"]
        profile['blacklist'] = []
        profile.save
      end
      desc 'list profile', 'list patterns in blacklist'
      def list(name)
        uconf = UserConfig.new '.recluse'
        unless uconf.exist?("#{name}.yaml")
          puts "Profile #{name} doesn't exist"
          exit(-1)
        end
        profile = uconf["#{name}.yaml"]
        profile['blacklist'].each { |pattern| puts pattern } if profile.key?('blacklist')
      end
    end
  end
end
