require "spec_helper"

module EntityPathSpec
  class ExampleEntity < Shamu::Entities::Entity
    attribute :id
  end
end

describe Shamu::Entities::EntityPath do

  {
    "User[45]/Calendar[567]/Event[1]" => [
                                           [ "User", "45" ],
                                           [ "Calendar", "567" ],
                                           [ "Event", "1" ]
                                         ],
    "User[45]" => [ [ "User", "45" ] ],
    "EntityPathSpec::Example[91]" => [ [ "EntityPathSpec::Example", "91" ] ]
  }.each do |path, entities|
    it "decompose #{ path } to #{ entities }" do
      expect( Shamu::Entities::EntityPath.decompose_entity_path( path ) ).to eq entities
    end
  end

  {
    "User[45]/Calendar[567]/Event[1]" => [
                                           [ "UserEntity", "45" ],
                                           [ "Calendar", "567" ],
                                           [ "Event", "1" ]
                                         ],
    "User[45]" => [ [ "User", "45" ] ],
    "User[37]" => [ "User[37]" ],
    "EntityPathSpec::Example[91]" => [ EntityPathSpec::ExampleEntity.new( id: 91 ) ]
  }.each do |path, entities|
    it "composes #{ entities } to #{ path }" do
      expect( Shamu::Entities::EntityPath.compose_entity_path( entities ) ).to eq path
    end
  end
end
