require 'mechanize'
require 'recluse/response'

module Recluse
  ##
  # Link checker
  class Queue
    ##
    # Create an empty queue
    def initialize(email, redirect: false)
      @links = []
      @run_if = proc { true }
      @on_complete = proc { |link, response| }
      @redirect = redirect
      @email = email
      @agent = Mechanize.new do |a|
        a.ssl_version = 'TLSv1'
        a.verify_mode = OpenSSL::SSL::VERIFY_NONE
        a.max_history = nil
        a.follow_meta_refresh = true
        a.keep_alive = false
        a.redirect_ok = @redirect
        a.user_agent = "Mozilla/5.0 (compatible; recluse/#{Recluse::VERSION}; +#{Recluse::URL}) #{@email}"
      end
    end

    ##
    # Add to queue.
    def add(link)
      @links += [*link]
    end

    ##
    # If the test is true, run the link. Procedure takes the link as input.
    def run_if(&block)
      @run_if = block
    end

    ##
    # Run when a link has been checked. Procedure takes the link and response as inputs.
    def on_complete(&block)
      @on_complete = block
    end

    ##
    # Run a link
    def run_link(link)
      response = Response.new
      return nil unless @run_if.call(link)
      begin
        response.page = @agent.get link.absolute
        response.code = response.page.code
        response.success = true
      rescue Mechanize::ResponseCodeError => code
        response.code = code.response_code
        response.success = false
      rescue => error
        response.errors = error
        response.success = false
      end
      @on_complete.call link, response
      response
    end

    ##
    # Run queue
    def run
      until @links.empty?
        link = @links.shift
        run_link link
      end
    end
  end
end
