require 'spec_helper'
require 'shamu/attributes'

describe Shamu::Attributes::FluidAssignment do
  let( :klass ) do
    Class.new do
      include Shamu::Attributes::Projection
      include Shamu::Attributes::Assignment
      include Shamu::Attributes::FluidAssignment

      def initialize( attributes )
        assign_attributes( attributes )
      end
    end
  end

  it "requires Attributes::Assignment first" do
    expect do
      Class.new do
        include Shamu::Attributes::FluidAssignment
      end
    end.to raise_error /Assignment/
  end


end