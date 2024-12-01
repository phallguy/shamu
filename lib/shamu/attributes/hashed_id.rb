module Shamu
  module Attributes
    module HashedId
      extend ActiveSupport::Concern

      module HashFuncs
        # https://stackoverflow.com/a/38240325/76456
        def hash_id(id)
          return if id.blank?

          return Value.new(id.to_model_id * 387_420_489 % 4_000_000_000)
        end

        def unhash_id(id)
          return if id.blank?

          if id.is_a?(Value)
            return id.to_model_id * 3_513_180_409 % 4_000_000_000
          else
            id.to_model_id
          end
        end

        def unhash_value(value)
          unhash_id(Value(value))
        end
      end

      extend HashFuncs

      def to_key
        [hash_id]
      end

      def hash_id(id = self.id)
        self.class.hash_id(id)
      end

      def unhash_id(id)
        selfr.class.unhash_id(id)
      end

      class_methods do
        include HashFuncs

        def Value(value) # rubocop:disable Naming/MethodName
          case value
          when nil then nil
          when Shamu::Attributes::HashedId::Value then value
          else Shamu::Attributes::HashedId::Value.new(value)
          end
        end
      end

      class Value < SimpleDelegator
        def initialize(object)
          super(object.to_model_id)
        end
      end
    end
  end
end
