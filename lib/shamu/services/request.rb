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
      include Shamu::Attributes
      include Shamu::Attributes::Assignment
      include Shamu::Attributes::TrimStrings
      include Shamu::Attributes::Validation

      # Applies the attributes of the request to the given model. Only handles
      # scalar attributes. For more complex associations, override in a custom
      # {Request} class.
      #
      # @param [Object] model or object to apply the attributes to.
      # @return [model]
      def apply_to(model)
        self.class.attributes.each_key do |name|
          method = :"#{name}="
          model.send(method, send(name)) if model.respond_to?(method) && set?(name)
        end

        model
      end

      # Entities are always immutable - so they are considered persisted. Use a
      # {Services::Request} to back a form instead.
      def persisted?
        if respond_to?(:id)
          !!id
        else
          false
        end
      end

      # Execute block if the request is satisfied by the service successfully.
      def on_success(&block)
        @on_success_blocks ||= []
        @on_success_blocks << block
      end

      # Execute block if the request is not satisfied by the service.
      def on_fail(&block)
        @on_fail_blocks ||= []
        @on_fail_blocks << block
      end

      # Execute block when the service is done processing the request.
      def on_complete(&block)
        @on_complete_blocks ||= []
        @on_complete_blocks << block
      end

      # Mark the request as complete and run any {#on_success} or #{on_fail}
      # callbacks.
      #
      # @param [Boolean] success true if the request was completed
      # successfully.
      def complete(success)
        if success
          @on_success_blocks && @on_success_blocks.each(&:call)
        else
          @on_fail_blocks && @on_fail_blocks.each(&:call)
        end

        @on_complete_blocks && @on_complete_blocks.each(&:call)
      end

      # Adds an error to {#errors} and returns self. Used when performing an
      # early return in a service method
      #
      # @example
      #   next request.error( :title, "should be clever" ) unless title_is_clever?
      #
      # @return [self]
      def error(*args)
        errors.add(*args)
        self
      end

      # Indicates the request was unable to complete and the adds an error if provided.
      #
      # @return [Result]
      def reject(*args)
        if args.present?
          errors.add(*args)
        end

        Shamu::Services::Result.new(request: self)
      end

      private

        def resolve_attributes(attributes)
          resolved = super

          if resolved.key?(model_name.param_key)
            resolved[model_name.param_key]
          else
            resolved
          end
        end

        class << self
          # Coerces a hash or params object to a proper {Request} object.
          # @param [Object] params to be coerced.
          # @return [Request] the coerced request.
          def coerce(params)
            if params.is_a?(self)
              params
            elsif params.respond_to?(:to_h) || params.respond_to?(:to_attributes)
              new(params)
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
          def coerce!(params)
            coerced = coerce(params)
            raise ArgumentError unless coerced.valid?

            coerced
          end

          REQUEST_ACTION_PATTERN = /(Create|Update|New|Change|Delete)?(Request)?$/

          # @return [ActiveModel::Name] used by url_helpers or form_helpers etc.
          #   when generating model specific names for this request.
          def model_name
            @model_name ||= begin
              base_name = name || ""
              parts     = reduce_model_name_parts(base_name.split("::"))
              parts     = ["Request"] if parts.empty?
              base_name = parts.join("::")

              ::ActiveModel::Name.new(self, nil, base_name)
            end
          end

          private

            def reduce_model_name_parts(parts)
              while last = parts.last
                if last == "Request"
                  parts[-1] = parts[-2].singularize
                  break
                end

                last.sub!(REQUEST_ACTION_PATTERN, "")
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
