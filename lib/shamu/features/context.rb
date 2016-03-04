require "socket"

module Shamu
  module Features

    # Captures the environment and request specific context used to match
    # {Toggle} selectors and determine if a feature should be enabled.
    class Context
      include Shamu::Attributes

      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [Time] the current time.
      attribute :time do
        Time.zone ? Time.zone.now : Time.now
      end

      # @!attribute
      # @return [Array<Symbol>] roles assigned to the current user.
      attribute :roles

      # @!attribute
      # @return [String] the name of the host machine.
      attribute :host do
        Socket.gethostname
      end

      # @!attribute
      # @return [Integer,String] id of the current user - either an Integer, or a UUID.
      attribute :user_id

      # @!attribute
      # @return [Scorpion] used to dynamically look up dependencies by
      #     {Conditions}.
      attribute :scorpion

      #
      # @!endgroup Attributes

      def initialize( features_service, **attributes )
        @features_service = features_service
        super( **attributes )
      end

      # Retrieve a value from the host machine's environment. Abstracts over the
      # ENV hash to permit some filtering and to facilitate specs.
      #
      # @param [String] name of the environment variable.
      # @return [String] the environment variable.
      def env( name )
        ENV[name]
      end

      # Check if feature is enabled.
      def enabled?( name )
        features_service.enabled?( name )
      end

      # Remember the toggle selection in persistent storage for the user so that
      # they will receive the same result each time.
      def sticky!
        @sticky = true
        self
      end

      # @return [Boolean] true if the feature election should be remembered
      #     between requests.
      def sticky?
        @sticky
      end

      private

        attr_reader :features_service
    end
  end
end