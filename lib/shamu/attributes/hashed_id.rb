module Shamu
  module Attributes
    module HashedId
      extend ActiveSupport::Concern

      def to_key
        [hash_id(id)]
      end

      module HashFuncs
        # https://stackoverflow.com/a/38240325/76456
        def hash_id(id)
          return id.to_i * 387_420_489 % 4_000_000_000
        end

        def unhash_id(id)
          return id.to_i * 3_513_180_409 % 4_000_000_000
        end
      end

      include HashFuncs

      class_methods do
        include HashFuncs
      end
    end
  end
end
