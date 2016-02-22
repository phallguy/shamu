module Shamu
  module Rails

    # Integrate Shamu with rails.
    class Railtie < ::Rails::Railtie

      rake_tasks do
        rake_path = File.expand_path( "../../tasks/*.rake" )
        Dir[ rake_path ].each { |f| load f }
      end
    end
  end
end