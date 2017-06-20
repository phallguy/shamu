require "active_model"

module Shamu

  # Adds `to_model_id` to several classes that are often used to look up
  # models by id.
  module ToModelIdExtension

    # @param [String,Integer,#to_model_id] value
    # @return [Boolean] true if the value looks like an ID.
    def self.model_id?( value )
      case Array( value ).first
      when Integer then true
      when String  then ToModelIdExtension::Strings::NUMERIC_PATTERN =~ value
      end
    end

    # Extend common classes to add `to_model_id` method.
    def self.extend!
      Integer.include Integers
      String.include Strings
      Array.include Enumerables
      NilClass.include Integers

      ActiveRecord::Base.include Models if defined? ActiveRecord::Base
    end

    # Add `to_model_id` to String types.
    module Strings
      NUMERIC_PATTERN = /\A\s*[0-9]+\z/

      def to_model_id
        self =~ NUMERIC_PATTERN ? to_i : nil
      end
    end

    # Add `to_model_id` to Integer types.
    module Integers
      def to_model_id
        self
      end
    end

    # Add `to_model_id` to Enumerable types.
    module Enumerables
      def to_model_id
        map( &:to_model_id )
      end
    end

    # Add `to_model_id` to ActiveModel types.
    module Models
      def to_model_id
        id
      end
    end
  end
end

Shamu::ToModelIdExtension.extend!
