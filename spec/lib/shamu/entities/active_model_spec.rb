require 'spec_helper'
require 'shamu/entities'
require 'shamu/entities/active_model'

class ModelEntity < Shamu::Entities::Entity
  include Shamu::Entities::ActiveModel
end

module Nested
  class SetEntity < ModelEntity
  end
end

describe Shamu::Entities::ActiveModel do
  {
    "SetEntity"                     => "Set",
    "Set"                           => "Set",
    "Domain::SetEntity"             => "Set",
    "Domain::SubDomain::SetEntity"  => "SubDomain::Set",
    "Domain::SubDomain::SetsEntity" => "SubDomain::Set",
  }.each do |full_name, expected|

    it "maps #{ full_name } to #{ expected }" do
      klass =
        Class.new( Shamu::Entities::Entity ) do
          include Shamu::Entities::ActiveModel
        end
      klass.define_singleton_method :name do
        full_name
      end

      expect( klass.model_name.name ).to eq expected
    end
  end

end