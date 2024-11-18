# frozen_string_literal: true

module Shamu
  module Security
    class RoleEntity < ::Shamu::Entities::Entity
      model :role

      # @!attribute
      # @return [Symbol]
      attribute :id do
        name
      end

      # @!attribute
      # @return [Symbol] name of the role
      attribute :name do
        defined_role[:name]
      end

      # @!attribute
      # @return [String] name of the role
      attribute :title do
        defined_role[:title]
      end

      # @!attribute
      # @return [Array<Symbol>] security scopes the role is eligible for.
      attribute :scopes do
        defined_role[:scopes]
      end

      # @!attribute
      # @return [Boolean] if the role is assigned implicitly by system.
      attribute :implicit do
        defined_role[:implicit]
      end

      def implicit?
        !!implicit
      end

      # @!attribute
      # @return [Array<Symbol>]
      attribute :inherited_ids do
        defined_role[:inherits] || []
      end

      def inherited
        @inherited ||= inherited_ids.map do |role|
          self.class.new(role: role)
        end
      end

      # @!attribute
      # @return [Hash] the role hash defined by the {Roles.role)
      def defined_role
        raise(Shamu::NotImplementedError)
      end
    end
  end
end
