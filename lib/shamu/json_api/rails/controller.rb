require "rack"

module Shamu
  module JsonApi
    module Rails
      # Add support for writing resources as well-formed JSON API.
      module Controller
        extend ActiveSupport::Concern

        # Pattern to identify request params that hold 'ids'
        ID_PATTERN = /\A(id|.+_id)\z/

        included do
          before_action do
            if params[:include]
              render json: json_error("The 'include' parameter is not supported"), status: :bad_request
            end
          end

          rescue_from Exception, with: :render_unhandled_exception unless ::Rails.env.test?

          helper_method :json_resource
        end

        private

          # @!visibility public
          #
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
          def json_resource(resource, presenter = nil, **context)
            response = build_json_response(context)
            response.resource(resource, presenter)
            yield(response) if block_given?
            response.as_json
          end

          # @!visibility public
          #
          # Present the `resource` as json and render it adding appropriate
          # HTTP response codes and headers for standard JSON API actions.
          #
          # @param [Symbol,Number] status the HTTP status code.
          # @param (see #json_resource)
          def render_resource(resource, presenter: nil, status: nil, location: nil, **context, &)
            json = json_resource(resource, presenter, **context, &)

            # Include canonical url to resource if present
            if (data = json["data"]) && (links = data["links"]) && links["self"]
              location ||= links["self"]
            end

            render(json: json, status: status, location: location)
          end

          # @!visibility public
          #
          # Renders a {Shamu::Services::Result} presenting either the
          # validation errors or the entity.
          #
          # @param [Shamu::Services::Result] result of a service call
          # @param (see #json_resource)
          def render_result(result, presenter: nil, status: nil, **context, &)
            if result.valid?
              if result.entity
                status ||= case request.method
                           when "POST"   then :created
                           when "DELETE" then :no_content
                           else               :ok
                           end

                render_resource(result.entity, presenter: presenter, status: status, **context, &)
              else
                head(status || :no_content)
              end
            else
              render(json: json_validation_errors(result.errors, **context), status: :unprocessable_entity)
            end
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
          def json_collection(resources, presenter = nil, pagination: :auto, **context)
            response = build_json_response(context)
            response.collection(resources, presenter)
            json_paginate_resources(response, resources, pagination)
            yield(response) if block_given?
            response.as_json
          end

          # Present the resources as json and render it adding appropriate HTTP
          # response codes and headers.
          def render_collection(resources, presenter: nil, pagination: :auto, **context, &)
            render(json: json_collection(resources, presenter, pagination: pagination, **context, &))
          end

          # Write all the validation errors from a record to the response.
          #
          # @param (see Shamu::JsonApi::Response#validation_errors)
          # @yield (builder, attr, message)
          # @yieldparam (see Shamu::JsonApi::Response#validation_errors)
          # @return [JsonApi::Response] the presented JSON response.
          def json_validation_errors(errors, **context, &)
            response = build_json_response(context)
            response.validation_errors(errors, &)

            response.as_json
          end

          # @!visibility public
          #
          # Add page-based pagination links for the resources to the builder.
          #
          # @param [#current_page,#next_page,#previous_page] resources a collection that responds to `#current_page`
          # @param [JsonApi::BaseBuilder] builder to add links to.
          # @param [String] param the name of the key page parameter to adjust
          # @return [void]
          def json_paginate(resources, builder, param: nil)
            page = resources.current_page

            if resources.respond_to?(:next?) ? resources.next? : true
              builder.link(:next, url_for(json_page_parameter(param, :number, page + 1)))
            else
              builder.link(:next, nil)
            end

            if resources.respond_to?(:prev?) ? resources.prev? : page > 1
              builder.link(:prev, url_for(json_page_parameter(param, :number, page - 1)))
            else
              builder.link(:prev, nil)
            end
          end

          def json_page_parameter(page_param_name, param, value)
            params = self.params
            params = params.to_unsafe_hash if params.respond_to?(:to_unsafe_hash)

            root = page_param_name ? params[page_param_name].try(:permit!) : params

            page_params = root.reverse_merge(page: {})
            if value > 1
              page_params[:page][param] = value
            else
              page_params[:page].delete(param)
            end

            page_param_name ? { page_param_name => page_params } : page_params
          end

          # @!visibility public
          #
          # Get the pagination request parameters.
          #
          # @param [Symbol] param the request parameter to read pagination
          #     options from.
          # @return [Pagination] the pagination state
          def json_pagination(param = nil)
            root = param ? params[param].try(:permit!) : params

            page_params =
              if root && (filter = root[:page])
                filter.permit!.to_hash.deep_symbolize_keys
              else
                {}
              end

            Pagination.new(page_params.merge(param: param))
          end

          # @!visibility public
          #
          # Write an error response. See {Shamu::JsonApi::Response#error} for details.
          #
          # @param (see Shamu::JsonApi::Response#error)
          # @yield (builder)
          # @yieldparam [Shamu::JsonApi::ErrorBuilder] builder to customize the
          #     error response.
          # @return [JsonApi::Response] the presented JSON response.
          def json_error(error = nil, **context)
            response = build_json_response(context)

            response.error(error) do |builder|
              builder.http_status(json_http_status_code_from_error(error))
              annotate_json_error(error, builder)
              yield(builder) if block_given?
            end

            response.to_json
          end

          def render_unhandled_exception(exception)
            render(json: json_error(exception), status: :internal_server_error)
          end

          # @!visibility public
          #
          # Annotate an exception that is being rendered to the browser - for
          # example to add current user or security information if available.
          def annotate_json_error(error, builder)
            return unless ::Rails.env.development?

            builder.meta(:type, error.class.to_s)
            builder.meta(:backtrace, error.backtrace)
          end

          JSON_CONTEXT_KEYWORDS = %i[fields namespaces presenters linkage_only].freeze

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
          #
          # @param [Boolean] linkage_only true to include only resource
          # identifier objects.
          #
          # @return [JsonApi::Context] the builder context honoring any filter
          #     parameters sent by the client.
          def json_context(fields: :not_set, namespaces: :not_set, presenters: :not_set, linkage_only: false)
            scorpion.fetch(
              Shamu::JsonApi::Context,
              fields: fields == :not_set ? json_context_fields : fields,
              namespaces: namespaces == :not_set ? json_context_namespaces : namespaces,
              presenters: presenters == :not_set ? json_context_presenters : presenters,
              linkage_only: linkage_only
            )
          end

          # @!visibility public
          #
          # Parameters to filter the specific JSON request by. Typically used
          # to constrain the results of a to-many relationsip.
          #
          # @param [Symbol] param name to fetch filter parameters from. Default
          # :filter.
          #
          # @return [Hash]
          def json_filter(param = nil)
            root = param ? params[param].try(:permit!) : params

            if root && (filter = root[:filter])
              filter.permit!.to_hash.deep_symbolize_keys
            else
              {}
            end
          end

          # @!visibility public
          #
          # The `sort` param parsed into a hash of pairs indicating the fields
          # to sort on and in which order.
          #
          # https://jsonapi.org/format/#fetching-sorting
          #
          # @return [Hash]
          def json_sort(param = nil)
            root = param ? params[param].try(:permit!) : params

            if root && (sort = root[:sort])
              sort.split(",").map(&:strip).each_with_object({}) do |attribute, parsed|
                if attribute[0] == "-"
                  parsed[attribute[1..-1].to_sym] = :desc
                else
                  parsed[attribute.to_sym] = :asc
                end
              end
            else
              {}
            end
          end

          # See (Shamu::Rails::Entity#request_params)
          def request_params(param_key)
            return {} unless json_request_payload.present?

            if json_request_payload.is_a?(Array)
              json_request_payload.map { |r| map_json_resource_payload(r) }
            else
              if (relationships = json_request_payload[:relationships]) && relationships.key?(param_key)
                return map_json_resource_payload(relationships[param_key][:data])
              end

              payload = map_json_resource_payload(json_request_payload)

              request.params.each do |key, value|
                payload[key.to_sym] ||= value if ID_PATTERN =~ key
              end

              payload
            end
          end

          def map_json_resource_payload(resource)
            payload = resource[:attributes] ? resource[:attributes].dup : {}
            payload[:id] = resource[:id] if resource.key?(:id)

            if relationships = resource[:relationships]
              relationships.each do |key, value|
                attr_key = "#{key.to_s.singularize}_id"

                if value[:data].is_a?(Array)
                  attr_key += "s" if value[:data].is_a?(Array)

                  payload[attr_key.to_sym] = value[:data].map { |d| d[:id] }
                  payload[key] = value[:data].map { |d| map_json_resource_payload(d) }
                else
                  payload[attr_key.to_sym] = value.dig(:data, :id)
                  payload[key] = value[:data].nil? ? nil : map_json_resource_payload(value[:data])
                end
              end
            end

            payload
          end

          # @!visibility public
          #
          # Map a JSON body to a hash.
          # @return [Hash, Array] the parsed JSON payload.
          def json_request_payload
            @json_request_payload ||=
              begin
                body = request.body.read || "{}"
                json = JSON.parse(body, symbolize_names: true)

                raise(NoJsonBodyError) unless json.present? && json.key?(:data)

                json[:data]
              end
          end

          def json_context_fields
            params[:fields]
          end

          def json_context_namespaces
            name = self.class.name.sub(/Controller$/, "")
            namespaces = [name.pluralize]
            loop do
              name = name.deconstantize
              break if name.blank?

              namespaces << name
            end

            namespaces
          end

          def json_context_presenters; end

          def json_paginate_resources(response, resources, pagination)
            pagination = resources.respond_to?(:paged?) && resources.paged? if pagination == :auto
            return unless pagination

            json_paginate(resources, response)
          end

          def json_http_status_code_from_error(error)
            case error
            when ActiveRecord::RecordNotFound, ::Shamu::NotFoundError then :not_found
            when ActiveRecord::RecordInvalid then :unprocessable_entity
            when /AccessDenied/, Security::AccessDeniedError then :unauthorized
            else
              if error.is_a?(Exception)
                ActionDispatch::ExceptionWrapper.status_code_for_exception(error)
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

          def build_json_response(context)
            Shamu::JsonApi::Response.new(json_context(**context.slice(*JSON_CONTEXT_KEYWORDS)))
          end
      end
    end
  end
end
