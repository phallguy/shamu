module Shamu
  module Security
    # Mixin for {Policy} and {Support} classes to define security roles
    # including inheritance.
    module Roles
      def self.included(into)
        into.extend(ClassMethods)
      end

      module ClassMethods
        # @return [Hash] the named roles defined on the class.
        def roles
          @roles ||= {}
        end

        def included(into)
          into.extend(ClassMethods)

          roles = self.roles
          into.define_singleton_method(:roles) do
            roles
          end
        end

        # Define a named role.
        #
        # @param [Symbol] name of the role.
        # @param [Array<Symbol>] inherits additional roles that are
        #     automatically inherited when the named role is granted.
        # @param [Array<Symbol>] scopes that the role may be granted in.
        # @param [Integer] bit to associate with the role if stored as a
        # bitmask
        # @return [void]
        def role(name, title: name.to_s.titleize, inherits: nil, scopes: nil, implicit: false, bit: :not_set)
          bit = implicit ? nil : roles.length if bit == :not_set

          roles[ name.to_sym ] = {
            name: name,
            title: title,
            inherits: Array(inherits),
            scopes: Array(scopes),
            implicit: implicit,
            bit: bit,
          }
        end

        # Expand the given roles to include the roles that they have inherited.
        # @param [Array<Symbol>] roles
        # @return [Array<Symbol>] the expanded roles.
        def expand_roles(*roles)
          expand_roles_into(roles, Set.new).to_a
        end

        # @param [Symbol] the role to check.
        # @return [Boolean] true if the role has been defined.
        def role_defined?(role)
          roles.key?(role.to_sym)
        end

        private

          def expand_roles_into(roles, expanded)
            raise "No roles defined for #{name}" unless self.roles.present?

            roles.each do |name|
              name = name.to_sym

              if name == :all
                expanded.merge(self.roles.keys)
                next
              end

              next unless role = self.roles[name]

              expanded << name

              role[:inherits].each do |inherited|
                next if expanded.include?(inherited)

                expanded << inherited
                expand_roles_into([inherited], expanded)
              end
            end

            expanded
          end
      end
    end
  end
end
