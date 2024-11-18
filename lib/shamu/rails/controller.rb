module Shamu
  module Rails
    # Adds convenience methods to a controller to access services and process
    # entities in response to common requests. The mixin is automatically added
    # to all controllers.
    #
    # ```
    # class UsersController < ApplicationController
    #   service :users_service, Users::UsersService
    # end
    # ```
    module Controller
      extend ActiveSupport::Concern

      included do
        include Scorpion::Rails::Controller

        # ActionController::API does not have #helper_method
        if respond_to?(:helper_method)
          helper_method :permit?
          helper_method :current_user
        end

        # In `included` block so that it overrides Scorpion controller method.

        def prepare_scorpion(scorpion)
          super

          scorpion.prepare do |s|
            s.hunt_for(Shamu::Security::Principal) do
              security_principal
            end
          end
        end
      end

      private

        # The currently logged in user. Must respond to #id when logged in.
        def current_user_id; end

        # @!visibility public
        #
        # @return [Array<Services::Service>] the list of services available to the
        #     controller.
        def services
          @services ||= self.class.services.map { |n| send(n) }
        end

        # @!visibility public
        #
        # @return [Array<Services::Service>] the list of services that can
        #     determine permissions for the controller.
        def secure_services
          @secure_services ||= services.select { |s| s.respond_to?(:permit?) }
        end

        # @!visibility public
        #
        # Checks if the requested behavior is permitted by any one of the
        # {#secure_services}.
        #
        # See {Security::Policy#permit?} for details.
        #
        # @overload permit?( action, resource, additional_context = nil )
        # @param (see Security::Policy#permit?)
        # @return (see Security::Policy#permit?)
        def permit?(*args)
          secure_services.any? { |s| s.permit?(*args) }
        end

        # @!visibility public
        #
        # Gets the security principal for the current request.
        #
        # @return [Shamu::Security::Principal]
        def security_principal
          @security_principal ||= Shamu::Security::Principal.new( \
            user_id: current_user_id,
            remote_ip: remote_ip,
            elevated: session_elevated?
          )
        end

        # @!visibility public
        #
        # @return [String] the IP address that the request originated from.
        def remote_ip
          request.env["HTTP_X_REAL_IP"] || request.remote_ip
        end

        # @!visibility public
        #
        # Override to indicate if the user has offerred their credentials this
        # session rather than just using a 'remember me' style token
        #
        # @return [Boolean] true if the session has been elevated.
        def session_elevated?; end

        class_methods do
          # @return [Array<Symbol>] the list of service names on the controller.
          def services
            @services ||= superclass.respond_to?(:services) ? superclass.services.dup : []
          end

          # Define a service dependency on the controller. Each request will get
          # its own instance of the service.
          #
          # @param [Symbol] name of the attribute the service should be accessible
          #     through.
          # @param [Class] contract the class of the service that should be
          #     resolved at runtime.
          # @param [Hash] options additional dependency options. See Scorpion
          #     attr_dependency for details.
          # @option options [Boolean] :lazy true if the service should be resolved
          #     the first time it's used instead of when the controller is
          #     initialized.
          # @return [name]
          def service(name, contract, lazy: true, **options)
            services << name
            attr_dependency(name, contract, **options.merge(private: true, lazy: lazy))
            name
          end
        end
    end
  end
end
