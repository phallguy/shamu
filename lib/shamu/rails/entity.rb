module Shamu
  module Rails

    # Manages loading an entity as part of a controller action. See {.entity}
    # for details.
    module Entity
      extend ActiveSupport::Concern

      private

        def fetch_entity( service, param )
          service.find( params[ param ] ) if params.key?( param )
        end

        def fetch_entities( service, param )
          service.list( param ? params[ param ] : params )
        end

        def fetch_entity_request( service, entity, param_key )
          action = params[ :action ].to_sym
          return unless service.respond_to?( :request_for )
          return unless request = service.request_for( action, entity )

          param_key ||= entity.model_name.param_key
          request.assign_attributes( request_params( param_key ) )

          service.authorize!( action, entity, request ) if service.respond_to?( :authorize! )
          request
        end

        # @!visibility public
        #
        # Get the raw request hash params for the given parameter key.
        # @param [Symbol] param_key key of the entity params to fetch.
        # @return [Hash] the params
        def request_params( param_key )
          strong_param = :"#{ param_key }_params"
          if respond_to?( strong_param, true )
            send( strong_param )
          else
            params[ param_key ]
          end
        end

        def load_entity( method:, list_method:, action: nil, only: nil, except: nil )
          action ||= params[ :action ].to_sym
          return unless matching_entity_action?( action, only: only, except: except )

          send list_action?( action ) ? list_method : method
        end

        def matching_entity_action?( action, only:, except: )
          return if only.present? && !only.include?( action )
          return if except.present? && except.include?( action )

          !create_action?( action )
        end

        def list_action?( action = params[ :action ] )
          action.to_sym == :index
        end

        def create_action?( action = params[ :action ] )
          [ :new, :create ].include?( action.to_sym )
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
        def entity( entity_class, through: nil, as: nil, list: nil, only: nil, except: nil, param: :id, list_param: nil, action: nil, param_key: nil ) # rubocop:disable Metrics/LineLength
          as      ||= entity_as_name( entity_class )
          through ||= :"#{ as.to_s.pluralize }_service"
          list    ||= as.to_s.pluralize.to_sym

          define_entity_method( as, through, param )
          define_entities_method( list, through, list_param )
          define_entity_request_method( as, through, param_key )

          before_action do
            load_entity( method: as,
                         list_method: list,
                         action: action,
                         only: only && Array( only ),
                         except: except && Array( except ) )
          end
        end

        private

          def entity_as_name( entity_class )
            entity_class.model_name.element
          end

          def define_entity_method( as, through, param )
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              private

              def #{ as }                                                                    # def entity
                return @#{ as } if defined? @#{ as }                                         #   return @entity if defined? @entity
                @#{ as } = fetch_entity( #{ through }, :#{ param } )                         #   @entity = fetch_entity( entity_service, :id )
              end                                                                            # end

              helper_method :#{ as } if respond_to?( :helper_method )
            RUBY
          end

          def define_entities_method( as, through, param )
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              private

              def #{ as }                                                                     # def entities
                return @#{ as } if defined? @#{ as }                                          #   return @entities if defined? @entities
                @#{ as } = fetch_entities( #{ through }, #{ param ? ":#{ param }" : 'nil' } ) #   @entities = fetch_entities( entity_service, nil )
              end                                                                             # end

              helper_method :#{ as } if respond_to?( :helper_method )
            RUBY
          end

          def define_entity_request_method( as, through, param )
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              private

              def #{ as }_request                                                              # def entity_request
                return @#{ as }_request if defined? @#{ as }_request                           #   return @entity_request if defined? @entity_request
                _entity = #{ as } unless create_action?                                        #   _entity = entity unless create_action?
                @#{ as }_request = fetch_entity_request( #{ through }, _entity, :#{ as } )     #   @entity_request = fetch_entity_request( entity_service, _entity, :entity )
              end                                                                              # end

              helper_method :#{ as }_request if respond_to?( :helper_method )
            RUBY
          end

      end
    end
  end
end
