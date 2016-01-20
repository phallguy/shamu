module Shamu

  # A set of errors. Provides just enough to record errors using
  # ActiveModel::Validations and report them inline using FormHelper.
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
      !messages[attribute].empty?
    end

    # @return [Boolean] true if there are no reported errors.
    def empty?
      messages.empty?
    end

    # @return [Array<String>] error messages recorded for the given attribute.
    def []( attribute )
      messages[attribute]
    end

  end
end