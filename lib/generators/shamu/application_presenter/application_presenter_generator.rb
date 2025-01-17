require "generators/rspec"
require "rails/generators/named_base"

module Shamu
  module Generators
    # @!visibility private
    class ApplicationPresenterGenerator < ::Rails::Generators::NamedBase
      desc "Generate the default application presenter"
      source_root File.expand_path("templates", __dir__)

      def copy_application_presenter_file
        copy_file("application_presenter.rb", "app/presenters/application_presenter.rb")
      end
    end
  end
end
