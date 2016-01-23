module Shamu
  module Services

    # Define the attributes and validations required to request a change by a
    # {Service}. You can use the Request in place of an ActiveRecord model in
    # rails forms_helpers.
    #
    # ```
    # module Document
    #   module Request
    #     class Change < Shamu::Services::Request
    #       attribute :title, presence: true
    #       attribute :author_id, presence: true
    #     end
    #
    #     class Create < Change
    #     end
    #
    #     class Update < Change
    #       attribute :id, presence: true
    #     end
    #   end
    # end
    # ```
    class Request
      include Shamu::Attributes::FluidAssignment
      include Shamu::Attributes::Validation

      # Applies the attributes of the request to the given model. Only handles
      # scalar attributes. For more complex associations, override in a custom
      # {Request} class.
      #
      # @param [Object] model or object to apply the attributes to.
      # @return [model]
      def apply_to( model )
        self.class.attributes.each do |name|
          method = :"#{ name }="
          model.send method, send( name ) if model.respond_to?( method )
        end
      end

      # Entities are always immutable - so they are considered persisted. Use a
      # {Services::ChangeRequest} to back a form instead.
      def persisted?
        if respond_to?( :id )
          !!id
        else
          fail NotImplementedError, "override persisted? in #{ self.class.name }"
        end
      end

      class << self
        # Coerces a hash or params object to a proper {Request} object.
        # @param [Object] params to be coerced.
        # @return [Request] the coerced request.
        def coerce( params )
          if params.is_a?( self )
            params
          elsif params.respond_to?( :to_h ) || params.respond_to?( :to_attributes )
            new( params )
          elsif params.nil?
            new
          else
            raise ArgumentError
          end
        end

        # Coerces the given params object and raises an ArgumentError if any of
        # the parameters are invalid.
        # @param (see .coerce)
        # @return (see .coerce)
        def coerce!( params )
          coerced = coerce( params )
          raise ArgumentError unless coerced.valid?
          coerced
        end

        REQUEST_ACTION_PATTERN = /(Create|Update|New|Change|Delete)?(Request)?$/

        # @return [ActiveModel::Name] used by url_helpers or form_helpers etc.
        #   when generating model specific names for this request.
        def model_name
          @model_name ||= begin
            base_name = name || ""
            parts     = reduce_model_name_parts( base_name.split( "::" ) )
            parts     = ["Request"] if parts.empty?
            base_name = parts.join "::"

            ::ActiveModel::Name.new( self, nil, base_name )
          end
        end

        private

          def reduce_model_name_parts( parts )
            while last = parts.last
              last.sub! REQUEST_ACTION_PATTERN, ""
              if last.empty?
                parts.pop
                next
              end

              last = last.singularize
              parts[-1] = last
              break
            end

            parts
          end
      end
    end
  end
end
