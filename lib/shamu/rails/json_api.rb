require "rack"

module Shamu
  module Rails

    # Add support for writing resources as well-formed JSON API.
    module JsonApi
      extend ActiveSupport::Concern

      included do
        before_action do
          json_api error: "The 'include' parameter is not supported", status: :bad_request if params[:include]
        end

        prepend_before_action do
        end
      end

      def process_action( * )
        # If no format has been specfied, default to json_api
        request.parameters[:format] ||= "json_api"
        super
      end

      # @!visibility public
      #
      # Writes a single resource as a well-formed JSON API response.
      #
      # @param [Object] resource to present as JSON.
      # @param [JsonApi::Presenter] presenter to use when building the
      #     response. If not given, attempts to find a presenter. See
      #     {#json_context}
      # @param (see #json_context)
      # @yield (response) write additional top-level links and meta
      #     information.
      # @yieldparam [JsonApi::Response] response
      # @return [JsonApi::Response] the presented json response.
      def json_resource( resource, presenter = nil, **context, &block )
        response = build_json_response( context )
        response.resource resource, presenter
        yield response if block_given?
        response
      end

      # @!visibility public
      #
      # Writes a single resource as a well-formed JSON API response.
      #
      # @param [Enumerabl<Object>] resources to present as a JSON array.
      # @param [JsonApi::Presenter] presenter to use when building the
      #     response. If not given, attempts to find a presenter. See
      #     {#json_context}
      # @param (see #json_context)
      # @yield (response) write additional top-level links and meta
      #     information.
      # @yieldparam [JsonApi::Response] response
      # @return [JsonApi::Response] the presented json response.
      def json_collection( resources, presenter = nil, pagination: :auto, **context, &block )
        response = build_json_response( context )
        response.collection resources, presenter
        json_paginate_resources response, resources, pagination
        yield response if block_given?
        response
      end

      # @!visibility public
      #
      # Add page-based pagination links for the resources.
      #
      # @param [#current_page,#next_page,#previous_page] resources a collection that responds to `#current_page`
      # @param [JsonApi::BaseBuilder] builder to add links to.
      # @param [String] param the name of the page parameter to adjust for
      def json_paginate( resources, builder, param: "page[number]" )
        page = resources.current_page

        if resources.respond_to?( :next_page ) ? resources.next_page : true
          builder.link :next, url_for( params.reverse_merge( param => resources.current_page + 1 ) )
        end

        if resources.respond_to?( :prev_page ) ? resources.prev_page : page > 1
          builder.link :prev, url_for( params.reverse_merge( param => resources.current_page - 1 ) )
        end
      end

      # @!visiblity public
      #
      # Write an error response. See {Shamu::JsonApi::Response#error} for details.
      #
      # @param (see Shamu::JsonApi::Response#error)
      # @return [Shamu::JsonApi::Response]
      # @yield (builder)
      # @yieldparam [Shamu::JsonApi::ErrorBuilder] builder to customize the
      #     error response.
      def json_error( error = nil, **context, &block )
        response = build_json_response( context )

        response.error error do |builder|
          builder.http_status json_http_status_code_from_error( error )
          yield builder if block_given?
        end

        response
      end

      # @!visiblity public
      #
      # Write all the validation errors from a record to the response.
      #
      # @param (see Shamu::JsonApi::Response#validation_errors)
      # @return [Shamu::JsonApi::Response]
      # @yield (builder, attr, message)
      # @yieldparam (see Shamu::JsonApi::Response#validation_errors)
      def json_validation_errors( record, **context, &block )
        response = build_json_response( context )
        response.validation_errors record, &block

        response
      end

      JSON_CONTEXT_KEYWORDS = [ :fields, :namespaces, :presenters ].freeze

      # @!visibility public
      #
      # Buid a {JsonApi::Context} for the current request and controller.
      #
      # @param [Hash<Symbol,Array>] fields to include in the response. If not
      #     provided looks for a `fields` request argument and parses that.
      #     See {JsonApi::Context#initialize}.
      # @param [Array<String>] namespaces to look for {Presenter presenters}.
      #     If not provided automatically adds the controller name and it's
      #     namespace.
      #
      #     For example in the `Users::AccountController` it will add the
      #     `Users::Accounts` and `Users` namespaces.
      #
      #     See {JsonApi::Context#find_presenter}.
      # @param [Hash<Class,Class>] presenters a hash that maps resource classes
      #     to the presenter class to use when building responses. See
      #     {JsonApi::Context#find_presenter}.
      def json_context( fields: :not_set, namespaces: :not_set, presenters: :not_set )
        Shamu::JsonApi::Context.new fields: fields == :not_set ? json_context_fields : fields,
                                    namespaces: namespaces == :not_set ? json_context_namespaces : namespaces,
                                    presenters: presenters == :not_set ? json_context_presenters : presenters
      end

      # rubocop:disable Metrics/PerceivedComplexity

      # @!visibility public
      #
      # Render a JSON API response for a resource, collection or error.
      #
      # @overload json_api( error:, status: :auto, **context, &block )
      #   @param [Exception] error an error to report
      #   @param [Symbol,Integer] status the HTTP status code to return. If
      #       :auto, attempts to determine the proper response from the
      #       exception and request type.
      #   @param (see #json_context)
      #   @param [String,#call] location to redirect to on success.
      # @overload json_api( resource:, status: :auto, presenter: nil, **context, &block )
      #   @param [Object] resource  the resource to render.
      #   @param [Symbol,Integer] status the HTTP status code. If :auto
      #       attempts to determine the proper response from the request type.
      #   @param (see #json_resource)
      #   @param [Shamu::JsonApi::Presenter] presenter to use when serializing
      #     the resource.
      #   @param [String,#call] location to redirect to on success.
      # @overload json_api( collection:, status: :ok, presenter: nil, **context, &block )
      #   @param [Array<Object>] collection to render.
      #   @param [Symbol,Integer] statis HTTP status code.
      #   @param (see #json_collection)
      #   @param [Shamu::JsonApi::Presenter] presenter to use when serializing
      #     each of the resources.
      #   @param [String,#call] location to redirect to on success.
      def json_api( error: nil, resource: nil, collection: nil, status: :auto, presenter: nil, pagination: :auto, location: nil, **context, &block ) # rubocop:disable  Metrics/LineLength
        options = { layout: nil }

        options[:json] =
          if error
            status = json_http_status_code_from_error( error ) if status == :auto
            json_error( error, **context, &block )
          elsif collection
            status = :ok if status == :auto
            json_collection( collection, presenter, pagination: pagination, **context, &block )
          else
            status = json_http_status_code_from_request if status == :auto
            json_resource( resource, presenter, **context, &block )
          end

        options[:status]   = status   if status
        options[:location] = location if location

        render options.merge( context.except( *JSON_CONTEXT_KEYWORDS ) )
      end

      private

        def json_context_fields
          params[:fields]
        end

        def json_context_namespaces
          name = self.class.name.sub /Controller$/, ""
          namespaces = [ name.pluralize ]
          loop do
            name = name.deconstantize
            break if name.blank?

            namespaces << name
          end

          namespaces
        end

        def json_context_presenters
        end

        def json_paginate_resources( response, resources, pagination )
          pagination = resources.respond_to?( :current_page ) if pagination == :auto
          return unless pagination

          json_paginate resources, response
        end

        def json_http_status_code_from_error( error )
          case error
          when ActiveRecord::RecordNotFound then :not_found
          when ActiveRecord::RecordInvalid  then :unprocessable_entity
          when /AccessDenied/               then :forbidden
          else
            if error.is_a?( Exception )
              ActionDispatch::ExceptionWrapper.status_code_for_exception( error )
            else
              :bad_request
            end
          end
        end

        def json_http_status_code_from_request
          case request.method
          when "POST"  then :created
          when "HEAD"  then :no_content
          else              :ok
          end
        end

        def build_json_response( context )
          Shamu::JsonApi::Response.new( json_context( **context.slice( *JSON_CONTEXT_KEYWORDS ) ) )
        end
    end
  end
end