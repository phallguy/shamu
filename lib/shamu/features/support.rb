module Shamu
  module Features
    # Add feature togggle support to an object.
    module Support
      extend ActiveSupport::Concern

      included do
        # ============================================================================
        # @!group Dependencies
        #

        # @!attribute
        # @return [Features::FeaturesService] the service used to resolve
        #     enabled features.
        attr_dependency :features_service, Features::FeaturesService, lazy: true

        #
        # @!endgroup Dependencies
      end

      private

        # @!visibility public
        #
        # Only execute the block if the current {Features::Context} has the
        # named featue enabled.
        #
        # @param [String] feature name.
        # @param [Boolean] override force the feature to be either on or off.
        # @yield Yields if the feature is enabled.
        # @yieldreturn the result of the block or nil if the feature wasn't
        #     enabled.
        def when_feature(feature, override: nil)
          yield if override.nil? ? feature_enabled?(feature) : override
        end

        # @!visibility public
        #
        # Determines if the given feature has been toggled.
        #
        # @param [Symbol] feature name of the feature to check.
        # @return [Boolean] true if the feature has been toggled on.
        def feature_enabled?(feature)
          features_service.enabled?(feature)
        end
    end
  end
end
