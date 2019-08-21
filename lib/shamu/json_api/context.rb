module Shamu
  module JsonApi
    class Context
      include Scorpion::Object

      # @param [Hash<Symbol,Array>] fields explicitly declare the attributes and
      #     resources that should be included in the response. The hash consists
      #     of a keys of the resource types and values as an array of fields to
      #     be included.
      #
      #     A String value will be split on `,` to allow for easy parsing of
      #     HTTP query parameters.
      #
      # @param [Array<String>] namespaces to look for resource {Presenter
      #     presenters}. See {#find_presenter}.
      #
      # @param [Hash<Class,Class>] presenters a hash that maps resource classes
      #     to the presenter class to use when building responses. See
      #     {#find_presenter}.
      def initialize( fields: nil, namespaces: [], presenters: {} )
        @included_resources = {}
        @all_resources = Set.new
        @fields = parse_fields( fields )
        @namespaces = Array( namespaces )
        @presenters = presenters || {}
      end

      # Add an included resource for a compound response.
      #
      # If no `presenter` and no block are provided a default presenter will be
      # obtained by calling {#find_presenter}.
      #
      # @param [Object] resource to be serialized.
      # @param [Class] presenter tpresenter {Presenter} class to use to
      #     serialize the `resource`. If not provided a default {Presenter} will
      #     be chosen.
      # @yield (builder)
      # @yieldparam [ResourceBuilder] builder to write embedded resource to.
      def include_resource( resource, presenter = nil, &block )
        return if all_resources.include?( resource )

        all_resources << resource
        included_resources[resource] ||= begin
          presenter ||= find_presenter( resource ) unless block
          { presenter: presenter, block: block }
        end
      end

      # Signals that the given resource was presented in the primary payload
      # and should not be included in the additional `included` resource.
      def dont_include_resource(resource)
        included_resources.delete(resource)
      end

      # Collects all the currently included resources and resets the queue.
      #
      # @return [Array<Object,Hash>] returns the the resource and presentation
      #     options from each resource buffered with {#include_resource}.
      def collect_included_resources
        included = included_resources.dup
        @included_resources = {}
        included
      end

      # @return [Boolean] true if there are any pending included resources.
      def included_resources?
        included_resources.any?
      end

      # Check to see if the field should be included in the JSON API output.
      #
      # @param [Symbol] type the resource type in question.
      # @param [Symbol] name of the field on the resouce in question.
      # @param [Boolean] default true if the field should be included by default
      #     when no explicit fields have been selected.
      # @return [Boolean] true if the field should be included.
      def include_field?( type, name, default = true )
        return default unless type_fields = fields[ type.to_sym ]

        type_fields.include?( name )
      end

      # Find a {Presenter} that can write the resource to a {ResourceBuilder}.
      #
      # - First looks for any explicit presenter given to the constructor that
      #   maps the resource's class to a specific presenter.
      # - Next, looks through each of the namespaces given to the constructor.
      #   For each namespace, looks for a `Namespace::#{ resource.class.name
      #   }Presenter`. Will also check `resource.class.model_name.name` if
      #   available.
      # - Fails with a {NoPresenter} error if a presenter cannot be found.
      #
      # @param [Object] resource to present.
      # @return [Class] the {Presenter} class to use.
      # @raise [NoPresenter] if a presenter cannot be found.
      def find_presenter( resource )
        presenter   = presenters[ resource.class ]
        presenter ||= presenters[ resource.class ] = find_namespace_presenter!( resource )

        presenter
      end

      # @return [Hash] of request param options to be output in the response meta.
      def params_meta
        return unless fields.any?

        { fields: fields }
      end

      private

        attr_reader :all_resources
        attr_reader :included_resources
        attr_reader :fields
        attr_reader :namespaces
        attr_reader :presenters

        def parse_fields( raw )
          return {} unless raw

          raw = raw.to_unsafe_hash if raw.respond_to?( :to_unsafe_hash )

          raw.each_with_object( {} ) do |(type, fields), parsed|
            fields = fields.split( "," ) if fields.is_a?( String )

            parsed[ type.to_sym ] = fields.map do |field|
              field = field.strip if field.is_a? String
              field.to_sym
            end
          end
        end

        def find_namespace_presenter!(resource)
          natural_namespaces = natural_namespaces_for(resource)
          candidate_namespaces = namespaces | natural_namespaces

          if presenter = find_namespace_presenter(resource, candidate_namespaces)
            return presenter
          end

          fail NoPresenter.new( resource, candidate_namespaces ) unless presenter
        end

        def find_namespace_presenter( resource, namespaces )
          presenter   = find_namespace_presenter_for( resource.class.name.demodulize, namespaces )
          presenter ||= find_namespace_presenter_for( resource.model_name.element.camelize, namespaces )       if resource.respond_to?( :model_name )        # rubocop:disable Metrics/LineLength
          presenter ||= find_namespace_presenter_for( resource.class.model_name.element.camelize, namespaces ) if resource.class.respond_to?( :model_name )  # rubocop:disable Metrics/LineLength
          presenter
        end

        def find_namespace_presenter_for( name, namespaces )
          name = "#{ name }Presenter".to_sym

          namespaces.each do |namespace|
            begin
              return "#{ namespace }::#{ name }".constantize
            rescue NameError # rubocop:disable Lint/HandleExceptions
            end
          end

          nil
        end

        def natural_namespaces_for(resource)
          parts = resource.class.name.split("::")
          parts.pop

          parts.each_with_object([]) do |part, ns|
            if ns.present?
              ns.push(ns.last + "::" + part)
            else
              ns.push(part)
            end
          end
        end

    end
  end
end
