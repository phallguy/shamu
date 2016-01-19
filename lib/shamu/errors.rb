module Shamu

  # A set of errors.
  class Errors
    include Enumerable

    # ============================================================================
    # @!group Attributes
    #

    # @return [Object] the object that errors are being reported on.
    attr_reader :base
    private :base

    # @return [Hash] the reported errors.
    attr_reader :messages

    #
    # @!endgroup Attributes

    def initialize( base )
      @base     = base
      @messages = Hash.new { |h, k| h[k] = [] }
    end

    # Adds an error to the set.
    #
    # @param [Symbol] attribute the error is associated with. Use `:base` to
    #   indicate the error is with the object itself.
    # @param [String] message to report.
    def add( attribute, message = "is invalid" )
      messages[attribute] << message
    end

    # @return [Boolean] true if there is an error reported for the given attribute
    def include?( attribute )
      !messages[attribute].blank?
    end

    # aliases include?
    alias has_key? include?

    # aliases include?
    alias key? include?

    # @return [Boolean] true if there are not reported errors.
    def empty?
      messages.empty?
    end

    # Iterate through each reported error.
    #
    # @yieldparam [Symbol] attribute
    # @yieldparam [String] message
    def each( &_block )
      messages.each do |attribute, msgs|
        msgs.each do |message|
          yield attribute, message
        end
      end
    end
  end
end