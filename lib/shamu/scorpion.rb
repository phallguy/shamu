# frozen_string_literal: true

require "scorpion"

module Scorpion
  def with_security_delegate
    @with_security_delegate ||=
      begin
        replica = replicate
        replica.hunt_for(::Shamu::Security::Principal, return: ::Shamu::Security::DelegatePrincipal.new)

        replica
      end
  end

  module Object
    private

      alias original_injection_scorpion_for injection_scorpion_for
      def injection_scorpion_for(attr)
        if attr.extensions[:delegate_security]
          return scorpion.with_security_delegate
        end

        original_injection_scorpion_for(attr)
      end

      module ClassMethods
        alias original_attr_dependency attr_dependency
        def attr_dependency(name, contract, **options)
          if options[:delegate_security]
            if options.key?(:lazy) && !options[:lazy]
              raise Shamu::InvalidOptionError, :delegate_security_must_be_lazy
            end

            options[:lazy] = true
          end

          original_attr_dependency(name, contract, **options)
        end
      end
  end
end
