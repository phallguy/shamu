require "rails/generators"
require "rails/generators/named_base"

module Shamu
  module Generators
    # @!visibility private
    class ServiceGenerator < ::Rails::Generators::NamedBase
      desc "Generate a simple service"
      source_root File.expand_path("templates", __dir__)

      check_class_collision
      check_class_collision suffix: "Request"
      check_class_collision suffix: "Service"

      class_option :service, type: :boolean, default: true
      class_option :request, type: :boolean, default: true
      class_option :test_framework

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

      private

        def skip_service?
          !service
        end

        def service
          options[:service]
        end

        def skip_request?
          !request
        end

        def request
          options[:request]
        end

        def skip_test_framework?
          !test_framework
        end

        def test_framework
          options[:test_framework]
        end

        def request_class_name
          (class_path + ["#{file_name}Request"]).map!(&:camelize).join("::")
        end

        def service_class_name
          (class_path + ["#{file_name}Service"]).map!(&:camelize).join("::")
        end
    end
  end
end
