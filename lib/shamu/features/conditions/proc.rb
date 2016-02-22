module Shamu
  module Features
    module Conditions

      # Match against a custom method. Due to their dynamic nature, proc
      # conditions are much slower and should be reserved for only a few
      # features.
      #
      # The proc is specified in the configuration by class and method name like
      #
      # ```yaml
      # # features.yml
      # commerce:
      #   buy_now:
      #     select:
      #     - proc: Commerce::BuyNow#match?
      # ```
      #
      # Shamu will instantiate a new instance of the `Commerce::BuyNow` class
      # and invoke the `match?` method passing the current {Features::Context}.
      #
      # The custom proj will also have access to the current {Scorpion} if it
      # includes the {Scorpion::Object} mixin.
      class Proc < Conditions::Condition
        include Scorpion::Object

        # (see Condition#match?)
        def match?( context )
          instance( context ).send( proc_method, context, toggle )
        end

        private

          def instance( context )
            context.scorpion.fetch( proc_class )
          end

          def proc_class
            @proc_class ||= proc_config.first.constantize
          end

          def proc_method
            proc_config.last
          end

          def proc_config
            @proc_config ||= config.split( "#" )
          end

      end

    end
  end
end