module Shamu
  module Services
    # Describes request that will be/has been performed by a service and the
    # associated data properties.
    class ObservedRequest
      include Shamu::Attributes

      # ============================================================================
      # @!group Attributes
      #

      # @!attribute
      # @return [Request] the original request submitted to the service. The
      # request may be modified by the observers.
      attribute :request

      # @return [Result] the result of a dependency that asked for the request
      # to be canceled.
      attr_reader :cancel_reason

      #
      # @!endgroup Attributes

      # Ask that the service cancel the request.
      #
      # @return [Result] a nested result that should be reported for why the
      # request was canceled.
      def request_cancel(result = Result.new)
        @cancel_reason = result
      end

      # @return [Boolean] true if an observer has asked the request to be
      # canceled.
      def cancel_requested?
        !!cancel_reason
      end

      # Execute block if the action was canceled by another observer.
      # @yield(result)
      # @yieldresult [Result]
      def on_canceled(&block)
        @on_cancel_blocks ||= []
        @on_cancel_blocks << block
      end

      # Mark the action as complete and run any {#on_success} or #{on_fail}
      # callbacks.
      #
      # @param [Result] result the result of the action. If valid success callbacks are invoked.
      # @param [Boolean] canceled true if the action was canceled and not
      # processed.
      #
      # @return [Result] the result of all the observed callbacks.
      def complete(result, canceled)
        invoke_callbacks(result, @on_cancel_blocks) if canceled

        result
      end

      private

        def invoke_callbacks(result, callbacks)
          return unless callbacks.present?

          callbacks.each do |callback|
            nested = callback.call(result)
            result.join(nested) if nested
          end

          result
        end
    end
  end
end
