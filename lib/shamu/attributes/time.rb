require "active_support/concern"

module Shamu
  module Attributes

    # Automatically trim whitespace from strings and treat empty strings as
    # nil.
    module TrimStrings
      extend ActiveSupport::Concern

      included do |base|
        raise "Must include Shamu::Attributes first." unless base < Shamu::Attributes
      end

      private

          def trim_string( value, style )
            return value unless value.is_a?( String )

            case style
            when :left  then value.lstrip
            when :right then value.rstrip
            when :both  then value.strip
            when :none  then value
            else raise ArgumentError, "#{ style } is not a valid trim style"
            end
          end

      class_methods do

        # Define a new attribute for the class.
        #
        # @param (see Projection::DSL#attribute)
        # @param [Symbol] trim how to trim the string. One of `:left`,
        # `:right`, `:both`, `true`.
        # @param [Boolean] nilify_blanks treat blank strings as nil values.
        #
        # @return [void]
        #
        # @example
        #
        #   class Params
        #     include Shamu::Attributes
        #     include Shamu::Attributes::Assignment
        #
        #     attribute :label, trim: true
        #   end
        def attribute( name, *args, **options, &block )
          super
        end

        private

          def define_attribute_assignment( name, trim: nil, nilify_blanks: true, ** )
            super

            trim =
              case trim
              when :left, :right then trim
              when true then :both
              when nil, false then :none
              else raise ArgumentError, "#{ style } is not a valid trim style"
              end

            body = []
            body << "value = trim_string( value, :#{ trim } )" if trim != :none
            body << "value = nil if value.is_a?( String ) && value.blank?" if nilify_blanks

            if body.present?
              mod = Module.new do
                module_eval <<-RUBY, __FILE__, __LINE__ + 1
                  private def clean_#{ name }( value )
                    #{ body.join( $/ ) }
                    super value
                  end
                RUBY
              end

              include mod
            end
          end

          def attribute_option_keys
            super + [ :trim, :nilify_blanks ]
          end

      end

    end
  end
end
