# frozen_string_literal: true

require "shamu"

module Shamu
  module Minitest
    NAME_SENTINEL = /(.+)_entities$/

    def method_missing(method, ...) # rubocop:disable Style/MissingRespondToMissing
      match = NAME_SENTINEL.match(method.name)
      fixture_set_name = match && match[1].pluralize
      if fixture_sets.key?(fixture_set_name)
        shamu_entity_fixture(fixture_set_name, ...)
      else
        super

      end
    end

    private

      def shamu_entity_fixture(...)
        records = send(...)

        service = scorpion.fetch(Array(records).first.service_class)

        if records.is_a?(Array)
          service.send(:build_entities, records)
        else
          service.send(:build_entity, records)
        end
      end
  end
end
