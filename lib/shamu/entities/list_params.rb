module Shamu
  module Entities

    # Parameters offered to a {Services::Service} to prepare a list of {Entity
    # entities}.
    class ListParams
      include Attributes
      include Attributes::Assignment
      include Attributes::FluidAssignment

      # # Coerces a hash or params object to a proper ListParams object.
      # def self.coerce( params )
      # end
    end
  end
end