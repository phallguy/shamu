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
        attr_dependency :features_service, Features::FeaturesService

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
        def when_feature( feature, override: nil, &block )
          if ( override.nil? && features_service.enabled?( feature ) ) || override
            yield
          end
        end

        def feature_enabled?( feature )
        end
    end
  end
end