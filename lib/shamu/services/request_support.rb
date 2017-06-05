module Shamu
  module Services

    # Include into services that support mutating resources to add basic
    # {#with_request} and {Request} conventions.
    module RequestSupport
      extend ActiveSupport::Concern

      # Used to interrogate the service for the {Request} class to use for a
      # given method.
      #
      # Combine with {Request#init_from} to prepare a request for use in a rails
      # form ready to modify an existing entity.
      #
      # @param [Symbol] method on the service that will be called.
      # @return [Class] a class that inherits from Request.
      def request_class( method )
        self.class.request_class( method )
      end

      # Build a {Request} object, prepopulated with the current state of the
      # resource to submit changes to the given `method`.
      #
      # @param [Symbol] method that will be called with the generated request.
      # @param [Entities::Entity] entity optional entity that will modified.
      # @return [Request]
      def request_for( method, entity = nil )
        request    = request_class( method ).new( entity )
        request.id = entity.id if entity && request.attribute?( :id )

        request
      end

      private

        # @!visibility public
        #
        # Respond to a {Request} returning a {Result} touple of the subject
        # {Entities::Entity} and {Request}.
        #
        # Before processing the `params` will be coerced and validated. If the
        # request is invalid, the method will immediately return without
        # yielding to the block.
        #
        # If the block yields an {Entities::Entity} it will be assigned as the
        # {Result#entity} in the returned {Result} object.
        #
        # @param [Request,Hash] params of the request.
        # @param [Class] request_class to coerce `params` to.
        # @yield (request)
        # @yieldparam [Request] request coerced and validated from `params`.
        # @yieldreturn [Entities::Entity,#errors] the entity manipulated during
        #   the request or an object that responds to #errors.
        # @return [Result]
        # @example
        #   def process_order( params )
        #     with_request params, ProcesOrderRequest do |request|
        #       order = Models::Order.find( request.id )
        #
        #       # Custom validation
        #       next error( :base, "can't do that" ) if order.state == 'processed'
        #
        #       request.apply_to( order )
        #
        #       # If DB only validations fail, return errors
        #       next order unless order.save
        #
        #       # All good, return an entity for the order
        #       scorpion.fetch OrderEntity, { order: order }, {}
        #     end
        #   end
        def with_request( params, request_class, &block )
          with_partial_request params, request_class do |request|
            next unless request.valid?

            yield request
          end
        end

        # @!visibility public
        #
        # Behaves the same as {#with_request} but always executes the block even
        # if the params are not yet valid. Allows the block to populate the
        # request with missing information before validating.
        #
        # @param (see #with_request)
        # @return (see #with_request)
        # @see #with_request
        def with_partial_request( params, request_class, &block )
          request = request_class.coerce( params )
          sources = yield( request )

          # Make sure the request captures errors even if the block doesn't
          # check
          request.valid?

          if sources.is_a?( Result )
            sources
          else
            result( *Array.wrap( sources ), request: request )
          end
        end

      # Static methods added to {RequestSupport}
      class_methods do

        # (see #request_class)
        def request_class( method )
          result = request_class_by_name( method ) \
                   || request_class_by_alias( method ) \
                   || request_class_default

          result ||= superclass.request_class( method ) if superclass.respond_to?( :request_class )

          result || fail( IncompleteSetupError, "No Shamu::Services::Request classes defined for '#{ name }'." )
        end

        private

          def request_class_namespace
            @request_class_namespace ||= ( name || "" ).sub( /(Service)?$/, "" )
                                                       .singularize
                                                       .concat( "Request" )
                                                       .constantize
          rescue NameError
            self
          end

          def request_class_by_name( method )
            camelized = method.to_s.camelize
            request_class_namespace.const_get( camelized ) if request_class_namespace.const_defined?( camelized )
          end

          def request_class_by_alias( method )
            candidate =
              case method
              when :new  then "Create"
              when :edit then "Update"
              end

            if candidate && request_class_namespace.const_defined?( candidate )
              request_class_namespace.const_get( candidate )
            end
          end

          def request_class_default
            request_class_namespace.const_get( "Change" ) if request_class_namespace.const_defined?( "Change" )
          end
      end
    end
  end
end
