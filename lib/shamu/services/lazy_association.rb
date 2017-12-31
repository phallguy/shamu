module Shamu
  module Services

    # Lazily look up an associated resource
    module LazyAssociation
      EXCLUDE_PATTERN = /\A(block_given\?|id|send|public_send|iterator|object_id|to_model_id|binding|class|kind_of\?|is_a\?|instance_of\?|respond_to\?|p.+_methods|__.+__)\z/ # rubocop:disable Metrics/LineLength
      MUTEX = Mutex.new

      def self.class_for( klass ) # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
        return klass.const_get( :Lazy_ ) if klass.const_defined?( :Lazy_ )

        MUTEX.synchronize do

          # Check again in case another thread defined it while waiting for the
          # mutex
          return klass.const_get( :Lazy_ ) if klass.const_defined?( :Lazy_ )

          lazy_class = Class.new( klass ) do
            # Remove all existing public methods so that they can be delegated
            # with #method_missing.
            klass.public_instance_methods.each do |method|
              next if EXCLUDE_PATTERN =~ method
              undef_method method
            end

            def initialize( id, &block )
              @id = id
              @block = block
            end

            # @!attribute
            # @return [Object] the primary key id of the association. Not delegated so
            #     it is safe to use and will not trigger an unnecessary fetch.
            attr_reader :id

            def __getobj__
              return @association if defined? @association

              @association = @block.call( @id ) if @block
            end

            def method_missing( method, *args, &block )
              if respond_to_missing?( method )
                __getobj__.public_send( method, *args, &block )
              else
                super
              end
            end

            def respond_to_missing?( method, include_private = false )
              __getobj__.respond_to?( method, include_private ) || super
            end
          end

          lazy_class.define_singleton_method :model_name do
            klass.model_name
          end

          klass.const_set( :Lazy_, lazy_class )
          lazy_class
        end
      end

    end
  end
end
