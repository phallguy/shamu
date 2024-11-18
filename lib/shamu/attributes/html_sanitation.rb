require "loofah"

module Shamu
  module Attributes
    # Adds an HTML sanitation option to attributes. When present, string values
    # will be sanitized when the attribute is read.
    #
    # The raw unfiltered value is always available as `#{ attribute }_raw`.
    module HtmlSanitation
      extend ActiveSupport::Concern

      # The standard HTML sanitation filter methods.
      STANDARD_FILTER_METHODS = [
        :none,      # Don't allow any HTML
        :simple,    # Allow very simple HTML. See {#simple_html_sanitize}.
        :body,      # Allow subset useful for body copy. See
        #   {#body_html_sanitize}.
        :safe, # Allow a broad subset of HTML tags and attributes. See
        #   {#safe_html_sanitize}.
        :allow, # Allow all HTML.
      ].freeze

      # Tags safe for simple text.
      SIMPLE_TAGS = %w[B I STRONG EM].freeze

      # Tags safe for body text.
      BODY_TAGS = %w[B BR CODE DIV EM H2 H3 H4 H5 H6 HR I LI OL P PRE SPAN STRONG U UL].freeze

      # Tags that are not safe.
      UNSAFE_TAGS = %w[FORM SCRIPT IFRAME FRAME].freeze

      class_methods do
        # (see Attributes.attribute)
        # @param [Symbol,#call] html sanitation options. Acceptable values are
        #
        #   - `:none` strip all HTML. The default.
        #   - `:simple` simple formatting suitable for most places. See
        #     {#simple_html_sanitize} for details.
        #   - `:body` basic formatting for 'body' text. See
        #     {#body_html_sanitize} for details.
        #   - `:allow` permit any HTML tag.
        #   - Any other symbol is assumed to be a method on the entity that will
        #     be called to filter the html.
        #   - `#call` anything that responds to `#call` that takes a single
        #     argument of the raw string and returns the sanitized HTML.
        def attribute(name, *args, **options, &block)
          super.tap do
            define_html_sanitized_attribute_reader(name, options[:html]) if options.key?(:html)
          end
        end

        private

          def define_attribute_reader(name, as: nil, **)
            super

            class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def #{name}_raw                                       # def attribute_raw
                return @#{name} if defined? @#{name}              #   return @attribute if defined? @attribute
                @#{name} = fetch_#{name}                          #   @attribute = fetch_attribute
              end                                                     # end
            RUBY
          end

          def define_html_sanitized_attribute_reader(name, method)
            method ||= :none

            filter_method = resolve_html_filter_method(name, method)
            class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def #{name}                                                               # def attribute
                return @#{name}_html_sanitized if defined? @#{name}_html_sanitized    #   return @attribute_html_sanitized if defined? @attribute_html_sanitized
                @#{name}_html_sanitized = #{filter_method}( #{name}_raw )           #   @attribute_html_sanitized = simple_html_sanitized( attribute_raw )
              end                                                                         # end
            RUBY
          end

          def resolve_html_filter_method(name, method)
            if STANDARD_FILTER_METHODS.include?(method)
              "#{method}_html_sanitize"
            elsif method.is_a?(Symbol)
              method
            else
              filter_method = "custom_#{name}_html_sanitize"
              define_method(filter_method, &method)
              filter_method
            end
          end
      end

      private

        # @!visibility public
        #
        # Remove all HTML from the value.
        #
        # @param [String] value to sanitize.
        # @return [String] the sanitized value.
        def none_html_sanitize(value)
          return value unless value.is_a?(String)

          Loofah.fragment(value).scrub!(NoneScrubber.new).to_s
        end

        # @!visibility public
        #
        # Remove all but the simplest html tags <B>, <I>, <STRONG>, <EM>.
        #
        # @param [String] value to sanitize.
        # @return [String] the sanitized value.
        def simple_html_sanitize(value)
          return value unless value.is_a?(String)

          Loofah.fragment(value).scrub!(SimpleScrubber.new).to_s
        end

        # @!visibility public
        #
        # Remove all but a limited subset of common tags useful for body copy
        # text. See {BODY_TAGS}.
        #
        # @param [String] value to sanitize.
        # @return [String] the sanitized value.
        def body_html_sanitize(value)
          return value unless value.is_a?(String)

          Loofah.fragment(value).scrub!(BodyScrubber.new).to_s
        end

        # @!visibility public
        #
        # Remove all HTML from the value.
        #
        # @param [String] value to sanitize.
        # @return [String] the sanitized value.
        def safe_html_sanitize(value)
          return value unless value.is_a?(String)

          Loofah.fragment(value)
                .scrub!(SafeScrubber.new)
                .scrub!(:no_follow)
                .to_s
        end

        # @!visibility public
        #
        # Does not perform any sanitization of the value.
        #
        # @param [String] value to sanitize.
        # @return [String] the sanitized value.
        def allow_html_sanitize(value)
          return value unless value.is_a?(String)

          Loofah.fragment(value).scrub!(:no_follow).to_s
        end

        class NoneScrubber < Loofah::Scrubber
          def initialize
            @direction = :bottom_up
          end

          def scrub(node)
            if node.text?
              Loofah::Scrubber::CONTINUE
            else
              node.before(node.children)
              node.remove
            end
          end
        end

        class PermitScrubber < Loofah::Scrubber
          def initialize
            @direction = :bottom_up
          end

          def scrub(node)
            if node.type == Nokogiri::XML::Node::ELEMENT_NODE
              if allowed_element?(node.name)
                Loofah::HTML5::Scrub.scrub_attributes(node)
              else
                node.before(node.children) unless unsafe_element?(node.name)
                node.remove
              end
            end

            Loofah::Scrubber::CONTINUE
          end

          def allowed_element?(name); end

          def unsafe_element?(name)
            UNSAFE_TAGS.include?(name.upcase)
          end
        end

        class SimpleScrubber < PermitScrubber
          def allowed_element?(name)
            SIMPLE_TAGS.include?(name.upcase)
          end
        end

        class BodyScrubber < PermitScrubber
          def allowed_element?(name)
            BODY_TAGS.include?(name.upcase)
          end
        end

        class SafeScrubber < PermitScrubber
          def allowed_element?(name)
            !unsafe_element?(name)
          end
        end
    end
  end
end