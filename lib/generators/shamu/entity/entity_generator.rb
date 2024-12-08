require "rails/generators"
require "rails/generators/named_base"
require "rails/generators/active_model"
require "rails/generators/model_helpers"
require "rails/generators/active_record"

module Shamu
  module Generators
    # @!visibility private
    class EntityGenerator < ::Rails::Generators::NamedBase
      include ::Rails::Generators::ModelHelpers

      desc "Generate an entity"
      source_root File.expand_path("templates", __dir__)

      source_paths << File.expand_path(File.join("test_unit", "model", "templates"), base_root)

      check_class_collision
      check_class_collision suffix: "Entity"
      check_class_collision suffix: "Request"
      check_class_collision suffix: "Service"
      check_class_collision suffix: "RolesService"

      class_option :migration, type: :boolean, default: true
      class_option :service, type: :boolean, default: true
      class_option :request, type: :boolean
      class_option :model, type: :boolean, default: true
      class_option :list, type: :boolean, default: true
      class_option :security, type: :boolean

      argument :attributes, type: :array, default: [], banner: "field[:type][:index] field[:type][:index]"

      hook_for :orm, in: :rails, as: :model do |instance, generator|
        generator.all_commands.each_key do |cmd|
          next if cmd == "create_model_file"
          next if cmd == "create_module_file"

          name = instance.name.split("/")
          name.shift
          name = name.join("/")
          instance.invoke(generator, cmd, [name, instance.attributes.map(&:to_s)])
        end
      end

      hook_for :test_framework, as: :model do |instance, generator|
        generator.all_commands.each_key do |cmd|
          next if cmd == "create_test_file"

          name = instance.name.split("/")
          name.shift
          name = name.join("/")
          instance.invoke(generator, cmd, [name, instance.attributes.map(&:to_s)])
        end
      end

      def create_entity_file
        template("entity.rb", File.join("app/services", class_path, "#{file_name}_entity.rb"))
      end

      def create_entity_test_file
        return if skip_test_framework?

        template("entity_test.rb", File.join("test/services", class_path, "#{file_name}_entity_test.rb"))
      end

      def create_model_file
        return if skip_model?

        template("model.rb", File.join("app/services", class_path, "models", "#{file_name}.rb"))
      end

      def create_model_test_file
        return if skip_model? || skip_test_framework?

        template("model_test.rb", File.join("test/services", class_path, "models", "#{file_name}_test.rb"))
      end

      def create_request_file
        return if skip_request?

        template("request.rb", File.join("app/services", class_path, "#{file_name}_request.rb"))
      end

      def create_request_test_file
        return if skip_request? || skip_test_framework?

        template("request_test.rb", File.join("test/services", class_path, "#{file_name}_request_test.rb"))
      end

      def create_service_file
        return if skip_service?

        template("service.rb", File.join("app/services", class_path, "#{file_name}_service.rb"))
      end

      def create_service_test_file
        return if skip_service? || skip_test_framework?

        template("service_test.rb", File.join("test/services", class_path, "#{file_name}_service_test.rb"))
      end

      def create_list_scope_file
        return if skip_list?

        template("list_scope.rb", File.join("app/services", class_path, "#{file_name}_list_scope.rb"))
      end

      def create_list_scope_test_file
        return if skip_list? || skip_test_framework?

        template("list_scope_test.rb", File.join("test/services", class_path, "#{file_name}_list_scope_test.rb"))
      end

      def create_policy_file
        return if skip_security?

        template("policy.rb", File.join("app/services", class_path, "#{file_name}_policy.rb"))
      end

      private

        def skip_service?
          !service
        end

        def service
          options[:service]
        end

        def skip_request?
          return skip_service? if request.nil?

          !request
        end

        def request
          options[:request]
        end

        def skip_model?
          !model
        end

        def model
          options[:model]
        end

        def skip_security?
          return skip_service? if security.nil?

          !security
        end

        def security
          options[:security]
        end

        def skip_test_framework?
          !test_framework
        end

        def skip_list?
          !options[:list] || skip_service?
        end

        def test_framework
          options[:test_framework]
        end

        def model_class_name
          (class_path + ["models", file_name]).map!(&:camelize).join("::")
        end

        def entity_class_name
          (class_path + ["#{file_name.camelize}Entity"]).map!(&:camelize).join("::")
        end

        def request_class_name
          (class_path + ["#{file_name.camelize}Request"]).map!(&:camelize).join("::")
        end

        def service_class_name
          (class_path + ["#{file_name.camelize}Service"]).map!(&:camelize).join("::")
        end

        def roles_service_class_name
          (class_path + ["#{file_name.camelize}RolesService"]).map!(&:camelize).join("::")
        end

        def policy_class_name
          (class_path + ["#{file_name.camelize}Policy"]).map!(&:camelize).join("::")
        end

        def policy_base_class_name
          if skip_model?
            "Shamu::Security::Policy"
          else
            "Shamu::Security::ActiveRecordPolicy"
          end
        end

        def list_scope_class_name
          (class_path + ["#{file_name.camelize}ListScope"]).map!(&:camelize).join("::")
        end
    end
  end
end
