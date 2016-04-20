require "rack"

module Shamu
  module Rails

    # Add support for writing resources as well-formed JSON API.
    module JsonApi
      extend ActiveSupport::Concern

      included do
        before_action do
          render json: json_error( "The 'include' parameter is not supported" ), status: :bad_request if params[:include] # rubocop:disable Metrics/LineLength
        end
      end

      def process_action( * )
        # If no format has been specfied, default to json_api
        request.parameters[:format] ||= "json_api"
        super
      end

      # Builds a well-formed JSON API response for a single resource.
      #
      # @param [Object] resource to present as JSON.
      # @param [Class] presenter {Presenter} class to use when building the
      #     response for the given resource. If not given, attempts to find a
      #     presenter by calling {Context#find_presenter}.
      # @param (see #json_context)
      # @yield (response) write additional top-level links and meta
      #     information.
      # @yieldparam [JsonApi::Response] response
      # @return [JsonApi::Response] the presented JSON response.
      def json_resource( resource, presenter = nil, **context, &block )
        response = build_json_response( context )
        response.resource resource, presenter
        yield response if block_given?
        response.to_json
      end

      # Builds a well-formed JSON API response for a collection of resources.
      #
      # @param [Enumerable<Object>] resources to present as a JSON array.
      # @param [Class] presenter {Presenter} class to use when building the
      #     response for each of the resources. If not given, attempts to find
      #     a presenter by calling {Context#find_presenter}
      # @param (see #json_context)
      # @yield (response) write additional top-level links and meta
      #     information.
      # @yieldparam [JsonApi::Response] response
      # @return [JsonApi::Response] the presented JSON response.
      def json_collection( resources, presenter = nil, pagination: :auto, **context, &block )
        response = build_json_response( context )
        response.collection resources, presenter
        json_paginate_resources response, resources, pagination
        yield response if block_given?
        response.to_json
      end

      # Add page-based pagination links for the resources to the builder.
      #
      # @param [#current_page,#next_page,#previous_page] resources a collection that responds to `#current_page`
      # @param [JsonApi::BaseBuilder] builder to add links to.
      # @param [String] param the name of the page parameter to adjust for
      # @return [void]
      def json_paginate( resources, builder, param: "page[number]" )
        page = resources.current_page

        if resources.respond_to?( :next_page ) ? resources.next_page : true
          builder.link :next, url_for( params.reverse_merge( param => resources.current_page + 1 ) )
        end

        if resources.respond_to?( :prev_page ) ? resources.prev_page : page > 1
          builder.link :prev, url_for( params.reverse_merge( param => resources.current_page - 1 ) )
        end
      end

      # Write an error response. See {Shamu::JsonApi::Response#error} for details.
      #
      # @param (see Shamu::JsonApi::Response#error)
      # @yield (builder)
      # @yieldparam [Shamu::JsonApi::ErrorBuilder] builder to customize the
      #     error response.
      # @return [JsonApi::Response] the presented JSON response.
      def json_error( error = nil, **context, &block )
        response = build_json_response( context )

        response.error error do |builder|
          builder.http_status json_http_status_code_from_error( error )
          yield builder if block_given?
        end

        response.to_json
      end

      # Write all the validation errors from a record to the response.
      #
      # @param (see Shamu::JsonApi::Response#validation_errors)
      # @yield (builder, attr, message)
      # @yieldparam (see Shamu::JsonApi::Response#validation_errors)
      # @return [JsonApi::Response] the presented JSON response.
      def json_validation_errors( errors, **context, &block )
        response = build_json_response( context )
        response.validation_errors errors, &block

        response.to_json
      end

      JSON_CONTEXT_KEYWORDS = [ :fields, :namespaces, :presenters ].freeze

      # @!visibility public
      #
      # Build a {JsonApi::Context} for the current request and controller.
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
      # @return [JsonApi::Context] the builder context honoring any filter
      #     parameters sent by the client.
      def json_context( fields: :not_set, namespaces: :not_set, presenters: :not_set )
        Shamu::JsonApi::Context.new fields: fields == :not_set ? json_context_fields : fields,
                                    namespaces: namespaces == :not_set ? json_context_namespaces : namespaces,
                                    presenters: presenters == :not_set ? json_context_presenters : presenters
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