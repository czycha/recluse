require 'mechanize'
require 'recluse/statuscode'

module Recluse
  ##
  # Response wrapper.
  class Response
    ##
    # +Mechanize::Page+ of the response page. Might be +nil+.
    attr_accessor :page

    ##
    # +StatusCode+ of the response.
    attr_reader :code

    ##
    # Error string if any.
    attr_accessor :errors

    ##
    # Whether the page was successfully accessed or not.
    attr_accessor :success

    ##
    # Create new response.
    def initialize(page: nil, errors: false, code: StatusCode.new('idk'), success: false)
      @page = page
      @code = code
      @errors = errors
      @success = success
    end

    ##
    # Set a new status code.
    def code=(new_code)
      @code = StatusCode.new new_code
    end
  end
end
