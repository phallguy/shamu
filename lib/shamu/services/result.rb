module Shamu
  module Services

    # The result of a {Service} {Request} capturing the validation errors
    # recorded while processing the request and the resulting
    # {Services::Entities::Entity} and {Request} used.
    class Result

      # ============================================================================
      # @!group Attributes
      #

      # @return [Request] the request submitted to the {Service}.
      attr_reader :request

      # @return [Entities::Entity] the entity created or changed by the request.
      attr_reader :entity

      #
      # @!endgroup Attributes

      # @param [Array<#errors>] validation_sources an array of objects that respond to `#errors`
      #   returning a {ActiveModel::Errors} object.
      # @param [Request] request submitted to the service. If :not_set, uses
      #   the first {Request} object found in the `validation_sources`.
      # @param [Entities::Entity] entity submitted to the service. If :not_set,
      #   uses the first {Request} object found in the `validation_sources`.
      def initialize( *validation_sources, request: :not_set, entity: :not_set )
        validation_sources.each do |source|
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

      private

        def append_error_source( source )
          return unless source.respond_to?( :errors )

          source.errors.each do |attr, message|
            errors.add attr, message unless errors.include? message
          end
        end
    end
  end
end