module Shamu
  module JsonApi
    module Rails

      # Support JSON API responses with the standard rails `#respond_with` method.
      module Responder

        # Render the response as JSON
        # @return [String]
        def to_json
          if has_errors?
            display_errors
          elsif get?
            display resource
          elsif put? || patch?
            display resource, :location => api_location
          elsif post?
            display resource, :status => :created, :location => api_location
          else
            head :no_content
          end
        end
        alias_method :to_json_api, :to_json

        protected

          # @visibility private
          def display( resource, given_options = {} )
            given_options.merge!( options )

            json =
              if resource.is_a?( Enumerable )
                controller.json_collection resource, **given_options
              else
                controller.json_resource resource, **given_options
              end

            super json, given_options
          end

          # @visibility private
          def display_errors
            controller.render format => controller.json_validation_errors( resource_errors ), :status => :unprocessable_entity # rubocop:disable Metrics/LineLength
          end

        private

          def validation_resource?( resource )
            resource.respond_to?( :valid? ) && resource.respond_to?( :errors )
          end

      end
    end
  end
end