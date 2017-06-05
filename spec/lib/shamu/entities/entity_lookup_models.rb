module EntityLookupServiceSpecs
  class ExamplesService < Shamu::Services::Service
  end

  class CustomService < Shamu::Services::Service
  end

  class ExampleEntity < Shamu::Entities::Entity
    attribute :id
  end
end
