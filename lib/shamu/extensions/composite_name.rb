# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/class"
require "active_support/core_ext/object"

module Shamu
  module Extensions
    # Provides support splitting a composite name into first, last, honorifics, etc.
    # methods for manipulating and querying the field.
    # @example
    #   class User
    #     include Extensions::CompositeName
    #     attr_accessor :name
    #   end
    #
    #   user = User.new name: "Mr. John Smith"
    #   user.first_name         # => John
    #   user.last_name          # => Smith
    module CompositeName
      extend ActiveSupport::Concern

      included do
        class_attribute :composite_name_method, instance_accessor: false
        self.composite_name_method = "name"

        class_attribute :honorifics, instance_accessor: false
        self.honorifics = %w[mr ms mrs miss dr prof capt captain professor doctor].freeze

        class_attribute :generationals, instance_accessor: false
        # http://refiddle.com/h3l
        self.generationals = (%w[jr sr] + [/\AX?(IX|IV|V?I{0,3})\z/]).freeze
      end

      # @return [String] The first name, parsed from {composite_name_method}
      def first_name
        get_name_part(:first)
      end

      # @return [String] The last name, parsed from {composite_name_method}
      def last_name
        get_name_part(:last)
      end

      # @return [String] The composite name without honorifics or middle names.
      def unhonored_name
        "#{get_name_part(:first)} #{get_name_part(:last)}".strip
      end

      # @return [String] A short version of the name.
      def short_name
        first_name || "#{honorific} #{last_name}".strip
      end
      alias display_name short_name

      # @return [String] The parsed composite name.
      def parsed_name
        get_name_part(:name)
      end

      # @return [String] The honorific if present parsed from {composite_name_method}
      def honorific
        get_name_part(:honorific)
      end

      # @return [String] The suffix indicator such as Jr, Sr, III etc. if present parsed from {composite_name_method}
      def suffix
        get_name_part(:suffix)
      end

      # @return [String] The middle name if present parsed from {composite_name_method}
      def middle_name
        get_name_part(:middle)
      end

      # @return [String] The name in legal format LAST, FIRST.
      # @param [Boolean] middle to include a middle name.
      def legal_name(middle = false)
        if name = last_name
          if first = first_name
            "#{name}, #{first} #{middle ? middle_name : ''}"
          else
            name
          end
        else
          first_name + " #{middle_name}"
        end.strip
      end

      # @return [String] The full name in legal format LAST, FIRST including any provided middle name.
      def full_legal_name
        legal_name(true)
      end

      private

        def get_name_part(part)
          parsed_composite_name[part]
        end

        def parsed_composite_name
          @parsed_composite_name = nil if @parsed_composite_name && @parsed_composite_name[:name] != composite_name
          @parsed_composite_name ||= self.class.parse_composite_name(composite_name)
        end

        def composite_name
          if (name = send(self.class.composite_name_method)) && name.include?(",")
            parts = name.split(/\s/)
            generationals = []
            generationals << parts.pop while self.class.generational?(parts.last)
            name = parts.join(" ")
            name = name.split(",", 2).reverse.map(&:strip).join(" ")
            name += " " + generationals.join(" ") if generationals.any?
          end
          name
        end

        module ClassMethods
          # Parses a composite name into it's constituent parts.
          def parse_composite_name(composite_name)
            parsed = { name: composite_name }
            if parsed[:name]
              return parse_email_name(composite_name) if /@/ =~ composite_name

              parts = parsed[:name].split(/\s/)
              if first_name_index = first_non_honorific(parts)
                parsed[:honorific] = parts.shift(first_name_index).join(" ")
                suffixes = []
                # Pull off generationals from the start. Common for legal representations of the name.
                suffixes << parts.shift while generational?(parts.first)

                parsed[:first] = parts.shift
                suffixes << parts.pop while generational?(parts.last)
                parsed[:middle] = parts.shift(parts.count - 1).join(",").gsub(/(\w{1,2})\./, "\\1") if parts.count > 1
                parsed[:last] = parts.last
                parsed[:suffix] = suffixes.join(" ")
              end

              parsed.each do |key, val|
                parsed[key] = nil if val.blank?
              end

              if !parsed[:last] && parsed[:honorific]
                parsed[:last] = parsed[:first]
                parsed[:first] = nil
              end

              if parsed[:name].upcase == parsed[:name] || parsed[:name].downcase == parsed[:name]
                parsed = Hash[parsed.map { |k, v| [k, v && v.titleize] }]
              end

            end
            parsed
          end

          def parse_email_name(composite_name)
            return unless composite_name

            username = composite_name.split(/@/).first
            username.gsub!(/[._-]+/, " ")
            username.gsub!(/[0-9]/, "")

            parse_composite_name(username.titleize)
          end

          def first_non_honorific(parts)
            parts.index { |word| !honorific?(word) }
          end

          def honorific?(word)
            word = word.downcase.gsub(/[^a-z]/i, "")
            honorifics.include?(word)
          end

          def generational?(word)
            word && generationals.detect { |p| p.is_a?(String) ? p.casecmp(word) == 0 : p === word }
          end
        end
    end
  end
end
