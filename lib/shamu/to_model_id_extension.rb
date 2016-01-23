require "active_model"

module Shamu

  # Adds `to_model_id` to several classes that are often used to look up
  # models by id.
  #
  # This extension is added by default in Rails. Use {.extend!} for other
  # frameworks.
  module ToModelIdExtension

    # Extend common classes to add `to_model_id` method.
    def self.extend!
      Integer.include Integers
      String.include Strings
      Array.include Enumerables

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
