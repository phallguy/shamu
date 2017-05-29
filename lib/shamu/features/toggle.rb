module Shamu
  module Features

    # A configured feature toggle.
    class Toggle < Entities::Entity

      TYPES = [
        "release",    # Feature is expected to become permanent and is used to
                      #  decouple deployment from production release. Relatively
                      #  short lived.
        "ops",        # Controlled by operations as a kill-switch or tuning
                      #   option. Cohorts are typically not dynamic and apply to
                      #   all users.
        "experiment", # Used to explore the efficacy of an option by testing it
                      #   on a subset of the total users.
        "segment",    # Long-lived toggle used to control access to a feature
                      #   based on some sort of user segmentation (e.g. dogfood,
                      #   internal, premium, etc.).
      ].freeze


      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [String] name of the toggle, namespaced using paths.
      attribute :name

      # @!attribute
      # @return [String] human friendly description of the toggle.
      attribute :description

      # @!attribute
      # @return [String] type of the toggle. Offers a hint at acceptable caching
      #     strategies.
      attribute :type

      # @!attribute
      # @return [Time] When the feature toggle should be at 100% and removed
      #     from the code base.
      #
      # Toggles, and the code selected by them should be removed as soon as
      # possible so that you don't have to maintain unused code. By explicitly
      # setting a date when the toggle is no longer to be used, the system can
      # help inform you when the code is no longer needed and can safely be
      # removed.
      attribute :retire_at

      # @!attribute
      # @return [Array<Selector>] selectors used to match environment conditions
      #     to determine if the flag should be enabled.
      attribute :selectors do
        Array( select ).map do |config|
          Selector.new( self, config )
        end
      end

      # The raw Hash read from the YAML file
      model :select

      #
      # @!endgroup Attributes

      # @param [Context] context the feature evaluation context.
      # @return [Boolean] true if the toggle should be enabled.
      def enabled?( context )
        if selector = matching_selector( context )
          !selector.reject
        end
      end

      # @param [Context] context the feature evaluation context.
      # @return [Boolean] true if the toggle is retired and should be always on.
      def retired?( context )
        !retire_at || context.time > retire_at
      end

      def initialize( attributes )
        fail ArgumentError, "Must provide a retire_at attribute for '#{ attributes[ 'name' ] }' toggle." unless attributes["retire_at"] # rubocop:disable Metrics/LineLength
        fail ArgumentError, "Type must be one of #{ TYPES } for '#{ attributes[ 'name' ] }' toggle." unless TYPES.include?( attributes["type"] ) # rubocop:disable Metrics/LineLength
        super
      end

      private

        def matching_selector( context )
          selectors.find { |s| s.match?( context ) }
        end

      class << self

        # Loads all the toggles from the YAML file at the given path.
        #
        # @param [String] path.
        # @return [Hash<String,Toggle>] of toggles by name.
        def load( path )
          toggles = {}
          load_from_path( path, toggles, ParsingState.new( nil, nil ) )

          toggles
        end

        private

          def load_from_path( path, toggles, state )
            path = File.expand_path( path, state.file_path )
            File.open( path, "r" ) do |file|
              yaml = YAML.load( file.read ) # rubocop:disable  Security/YAMLLoad
              parse_node( yaml, toggles, ParsingState.new( state.name, File.dirname( path ) ) )
            end
          end

          def parse_node( node, toggles, state )
            if toggle?( node )
              params = node.merge!( "name" => state.name )
              toggles[state.name] = Toggle.new( params )
            else
              parse_child_nodes( node, toggles, state )
            end
          end

          def parse_child_nodes( node, toggles, state )
            node.each do |key, child|
              if key == "import"
                load_from_path( child, toggles, state )
              else
                child_state = ParsingState.new( [ state.name, key ].compact.join( "/" ), state.file_path )
                parse_node( child, toggles, child_state )
              end
            end
          end

          TOGGLE_KEYS = %w( description retire_at type select ).freeze

          # Determines if the yaml entry with the given key is a toggle, or if
          # it's children themselves may be toggles.
          def toggle?( node )
            return unless node.is_a? Hash
            node.keys.all? { |k| TOGGLE_KEYS.include?( k ) }
          end

      end

      ParsingState = Struct.new( :name, :file_path )
    end
  end
end
