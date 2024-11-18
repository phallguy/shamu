module Shamu
  module JsonApi
    module BuilderMethods
      module Identifier
        # Write a resource linkage info.
        #
        # @param [String] type of the resource.
        # @param [Object] id of the resource.
        # @return [self]
        def identifier(type, id = :not_set)
          add_identifier(output, type, id)

          self
        end

        # (see BaseBuilder#compile)
        def compile
          require_identifier!
          super
        end

        # Determines the proper JSON type from a resource or type.
        # @param [#json_type, #model_name] type the resource or underlying type
        # of the json object.
        def json_type(type)
          type = type.json_type                  if type.respond_to?(:json_type)
          type = type.model_name.element         if type.respond_to?(:model_name)
          type = type.name.demodulize.underscore if type.is_a?(Module)

          type.to_s
        end

        private

          def add_identifier(output, type, id = :not_set)
            output[:type] = @type = json_type(type)

            output[:id] =
              if id == :not_set
                type.id.to_s if type.respond_to?(:id)
              else
                id.to_s
              end
          end

          attr_reader :type

          def require_identifier!
            raise(IncompleteResourceError) unless @identifier_satisfied || type
          end

          def identifier_satisfied!
            @identifier_satisfied = true
          end
      end
    end
  end
end
