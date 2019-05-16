require "generators/rspec"

module Shamu
  module Generators
    # @!visibility private
    class ApiControllerGenerator < ::Rails::Generators::Base
      desc "Generate the default api conroller for JSON API responses"
      source_root File.expand_path("templates", __dir__)

      def copy_api_controller_file
        copy_file "api_controller.rb", "app/controllers/api_controller.rb"
      end
    end
  end
end
