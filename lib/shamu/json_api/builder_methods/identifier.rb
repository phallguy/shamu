module Shamu
  module JsonApi
    module BuilderMethods
      module Identifier
        # Write a resource linkage info.
        #
        # @param [String] type of the resource.
        # @param [Object] id of the resource.
        # @return [self]
        def identifier( type, id = :not_set )
          output[:type] = @type = json_type( type )

          output[:id] =
            if id == :not_set
              type.id if type.respond_to?( :id )
            else
              id.to_s
            end

          self
        end

        # (see BaseBuilder#compile)
        def compile
          require_identifier!
          super
        end

        private

          attr_reader :type

          def json_type( type )
            type = type.json_type                  if type.respond_to?( :json_type )
            type = type.model_name.element         if type.respond_to?( :model_name )
            type = type.name.demodulize.underscore if type.is_a?( Module )

            type.to_s
          end

          def require_identifier!
            fail IncompleteResourceError unless type
          end

      end
    end
  end
end
