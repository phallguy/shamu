module Shamu
  module Services
    # Adds the ability for other services to observe requests on the service.
    #
    # In contrast to {Events} that are async and independent, observers are
    # called immediately when a request is performed and may influence the
    # behavior of the request.
    #
    # See {#ObserverSupport} for details on observing other services.
    module ObservableSupport
      # Ask to be notified of important actions as they are executed on the
      # service.
      #
      # @yield (observed_request)
      # @yieldparam [ObservedRequest] action
      def observe(&block)
        @observers ||= []
        @observers << block
      end

      private

        # @!visibility public
        #
        # Invoke a block notifying observers before the action is performed
        # allowing them to modify inputs or request the action be canceled.
        #
        # @param [Request] request the service request
        # @return [Result]
        # @yield [Request]
        def with_observers(request)
          observed = ObservedRequest.new(request: request)
          notify_observers(observed)

          returned =
            if observed.cancel_requested?
              request.error(:base, :canceled)
            else
              yield(request)
            end

          result = Result.coerce(returned, request: request)

          observed.complete(result, false)
        end

        # @!visibility public
        #
        # Notify all registered observers about the pending request.
        # @param [ObservedAction] observed_action
        def notify_observers(observed_action)
          return unless defined? @observers

          @observers.each do |observer|
            observer.call(observed_action)
          end
        end

        # Override {Shamu::Services::RequestSupport#with_partial_request} to make all requests observable.
        # {#audit_request audit the request}.
        def with_partial_request(*args, &block)
          super(*args) do |request|
            with_observers(request, &block)
          end
        end
    end
  end
end
