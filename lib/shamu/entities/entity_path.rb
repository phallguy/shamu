module Shamu
  module Entities

    # An entity path describes one or more levels of parent/child relationships
    # that can be used to navigate from the root entity to a target entity.
    #
    # Entity paths can be used to identify polymorphic relationships between
    # entities managed by difference services.
    module EntityPath
      extend self # rubocop:disable Style/ModuleFunction

      # Composes an array of entities describing the path from the root entity
      # to the leaf into a string.
      #
      # @example
      #   path = compose_entity_path([
      #             [ "User", "45" ],
      #             [ "Calendar", "567" ],
      #             [ "Event", "1" ]
      #           ])
      #   path # => "User[45]/Calendar[567]/Event[1]"
      #
      #   path = compose_entity_path( user )
      #   path # => "User[45]"
      #
      # @param [Array<Entities::Entity>] entities
      # @return [String]
      def compose_entity_path( entities )
        return unless entities.present?

        entities.map do |entity|
          compose_single_entity( entity )
        end.join( "/" )
      end

      # Decompose an entity path into an array of arrays of entity classes with
      # their ids.
      #
      # @example
      #   entities = decompose_entity_path( "User[45]/Calendar[567]/Event[1]" )
      #   entities # => [
      #            #      [ "User", "45" ],
      #            #      [ "Calendar", "567" ],
      #            #      [ "Event", "1" ]
      #            #    ]
      #
      # @param [String] path the composed entity path.
      # @return [Array<Array<String,String>>] the entities with their ids.
      def decompose_entity_path( path )
        return unless path.present?

        path.split( "/" ).map do |node|
          entity, id = node.split "["

          [ entity, id[ 0..-2 ] ]
        end
      end

      private

        def compose_single_entity( entity )
          case entity
          when Entities::Entity    then build_composed_entity_path( entity.class.model_name.name, entity.id )
          when Array               then build_composed_entity_path( entity_path_name( entity.first ), entity.last )
          when /([A-Z][a-z0-9]*)+/ then entity
          else                          fail "Don't know how to compose #{ entity }"
          end
        end

        def entity_path_name( entity )
          case entity
          when String then entity.sub( /Entity$/, "" )
          when Class  then Class.model_name.name
          else             fail "Don't know how to compose #{ entity }"
          end
        end

        def build_composed_entity_path( name, id )
          "#{ name }[#{ id }]"
        end

    end
  end
end
