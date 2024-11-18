module Shamu
  module Rails
    # Manages loading an entity as part of a controller action. See {.entity}
    # for details.
    module Entity
      extend ActiveSupport::Concern

      private

        def fetch_entity(service, param)
          service.find(params[param]) if params.key?(param)
        end

        def fetch_entities(service, param)
          service.list(list_params(param))
        end

        def fetch_entity_request(service, entity, param_key)
          action = params[:action].to_sym
          return unless service.respond_to?(:request_for)
          return unless request = service.request_for(action, entity)

          param_key ||= entity.model_name.param_key if entity
          request.assign_attributes(request_params(param_key))

          request
        end

        # @!visibility public
        #
        # Get the raw request hash params for the given parameter key.
        # @param [Symbol] param_key key of the entity params to fetch.
        # @return [Hash] the params
        def request_params(param_key)
          strong_param = :"#{param_key}_params"
          if respond_to?(strong_param, true)
            send(strong_param)
          else
            params[param_key]
          end
        end

        # Filtering and sorting params to apply when {#fech_entities fetching
        # the entities}.
        #
        # @param [Symbol] param_key to use when fetching nested parameters.
        def list_params(_param_key = nil)
          {}
        end

        def list_action?(action = params[:action])
          action.to_sym == :index
        end

        def create_action?(action = params[:action])
          %i[new create].include?(action.to_sym)
        end

        class_methods do
          # Declare an entity dependency to be resolved before the requested
          # controller action. Shamu will attempt to load an entity through the
          # service and make it available to the controller as an attribute and
          # a helper method.
          #
          # Adds a method named after the entity excluding the namespace and
          # "Entity" suffix (Users::UserEntity => #user). It also makes an
          # entity_request method available for mutating actions such as new,
          # create, update, edit, etc.
          #
          # ```
          # class UsersController < ApplicationController
          #   service :users_service, Users::UsersService
          #   entity Users::UserEntity
          #
          #   def show
          #     render json: { name: user.name, id: user.id }
          #   end
          #
          #   def update
          #     result = users_service.update( user_request )
          #     respond_with result
          #   end
          # end
          # ```
          #
          # @param [Class] entity_class an {Entities::Entity} class to be loaded.
          # @param [Symbol] through the name of the service to fetch the entity
          #     from. If not set, guesses the name of the service from the entity
          #     class.
          # @param [Symbol] as the name of the method to expose the entity
          #     through.
          # @param [Symbol] list the name of the method to expose the list of
          #     entities for index actions.
          # @param [Array<Symbol>] only load the entity only for the given
          #     actions.
          # @param [Array<Symbol>] except load the entity except for the given
          #     actions.
          # @param [Symbol] param the request param that holds the id of the
          #     entity.
          # @param [Symbol] list_param request param that hols list scope params.
          # @param [Symbol] param_key request param that holds the attributes used
          #     to populate the service change request.
          # @param [Symbol] action override the default action detection. For
          #     example always use :show for a secondary or root entity that is
          #     not being modified in an :update request.
          def entity(entity_class, through: nil, as: nil, list: nil, only: nil, except: nil, param: :id, list_param: nil, action: nil, param_key: nil)
            as      ||= entity_as_name(entity_class)
            through ||= :"#{as.to_s.pluralize}_service"
            list    ||= as.to_s.pluralize.to_sym

            define_entity_method(as, through, param)
            define_entities_method(list, through, list_param)
            define_entity_request_method(as, through, param_key)
          end

          private

            def entity_as_name(entity_class)
              entity_class.model_name.element
            end

            def define_entity_method(as, through, param)
              class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              private

              def #{as}                                                                    # def entity
                return @#{as} if defined? @#{as}                                         #   return @entity if defined? @entity
                @#{as} = fetch_entity( #{through}, :#{param} )                         #   @entity = fetch_entity( entity_service, :id )
              end                                                                            # end

              helper_method :#{as} if respond_to?( :helper_method )
              RUBY
            end

            def define_entities_method(as, through, param)
              class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              private

              def #{as}_list_params                                                         # def entities_list_params
                list_params( #{param ? ":#{param}" : 'nil'} )                                                     #   list_params( nil )
              end                                                                             # end

              def #{as}                                                                     # def entities
                return @#{as} if defined? @#{as}                                          #   return @entities if defined? @entities
                @#{as} = #{through}.list( #{as}_list_params  )                          #   @entities = entity_service.list( entity_list_params )
              end                                                                             # end

              helper_method :#{as} if respond_to?( :helper_method )
              RUBY
            end

            def define_entity_request_method(as, through, _param)
              class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              private

              def #{as}_request                                                              # def entity_request
                return @#{as}_request if defined? @#{as}_request                           #   return @entity_request if defined? @entity_request
                _entity = #{as} unless create_action?                                        #   _entity = entity unless create_action?
                @#{as}_request = fetch_entity_request( #{through}, _entity, :#{as} )     #   @entity_request = fetch_entity_request( entity_service, _entity, :entity )
              end                                                                              # end

              helper_method :#{as}_request if respond_to?( :helper_method )
              RUBY
            end
        end
    end
  end
end
