module Shamu
  module Services

    # The result of a {Service} {Request} capturing the validation errors
    # recorded while processing the request and the resulting
    # {Services::Entities::Entity} and {Request} used.
    class Result
      extend ActiveModel::Translation


      # ============================================================================
      # @!group Attributes
      #

      # @return [Request] the request submitted to the {Service}.
      attr_reader :request

      # @return [Entities::Entity] the entity created or changed by the request.
      attr_reader :entity

      # @return [Entities::Entity] the entity created or changed by the request.
      # @raise [ServiceRequestFailedError] if the result was not valid.
      def entity!
        valid!
        entity
      end

      # @return [Array<Object>] the values returned by the service call.
      attr_reader :values

      # @return [Object] the primary return value of the service call.
      attr_reader :value

      # @return [Object] the primary return value of the service call.
      # @raise [ServiceRequestFailedError] if the result was not valid.
      def value!
        valid!
        value
      end

      #
      # @!endgroup Attributes

      # @param [Array<Object,#errors>] values an array of objects that
      #   represent the result of the service call. If they respond to `#errors`
      #   those errors will be included in {#errors} on the result object itself.
      # @param [Request] request submitted to the service. If :not_set, uses
      #   the first {Request} object found in the `values`.
      # @param [Entities::Entity] entity submitted to the service. If :not_set,
      #   uses the first {Entity} object found in the `values`.
      def initialize( *values, request: :not_set, entity: :not_set )
        @values = values
        @value  = values.first

        values.each do |source|
          request = source if request == :not_set && source.is_a?( Services::Request )
          entity  = source if entity == :not_set && source.is_a?( Entities::Entity )

          append_error_source source
        end

        unless request == :not_set
          @request = request
          append_error_source request
        end

        unless entity == :not_set
          @entity = entity
          append_error_source entity
        end
      end

      # @return [Boolean] true if there were not recorded errors.
      def valid?
        errors.empty?
      end

      # @return [ActiveModel::Errors] errors gathered from all the validation sources.
      #     Typically the {#request} and {#entity}.
      def errors
        @errors ||= ActiveModel::Errors.new( self )
      end

      # Delegate model_name to request/entity
      def model_name
        ( request && request.model_name ) || ( entity && entity.model_name ) || ActiveModel::Name.new( self, nil, "Request" ) # rubocop:disable Metrics/LineLength
      end

      # @return [self]
      # @raise [ServiceRequestFailedError] if the result was not valid.
      def valid!
        raise ServiceRequestFailedError, self unless valid?
        self
      end

      private


        def append_error_source( source )
          return unless source.respond_to?( :errors )

          source.errors.each do |attr, message|
            errors.add attr, message unless errors[attr].include? message
          end
        end
    end
  end
end
