module Shamu
  module JsonApi
    module BuilderMethods
      module Identifier
        # Write a resource linkage info.
        #
        # @param [String] type of the resource.
        # @param [Object] id of the resource.
        # @return [self]
        def identifier( type, id = nil )
          output[:type] = @type = type.to_s
          output[:id]   = id.to_s

          self
        end

        # (see BaseBuilder#compile)
        def compile
          require_identifier!
          super
        end

        private

          attr_reader :type

          def require_identifier!
            fail IncompleteResourceError unless type
          end

      end
    end
  end
end