module Shamu
  module Entities

    # List params define the shape and filters desired by the client of a {List}
    # returned from a {Services::Service}.
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