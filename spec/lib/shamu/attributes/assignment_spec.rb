require 'spec_helper'
require 'shamu/attributes'

describe Shamu::Attributes::Assignment do
  let( :base_klass ) do
    Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::Assignment

      attribute :value
    end
  end

  it "requires Attributes::Projection first" do
    expect do
      Class.new do
        include Shamu::Attributes::Assignment
      end
    end.to raise_error /Attributes/
  end

  describe "arrays" do
    let( :klass ) do
      Class.new( base_klass ) do
        attribute :tags, coerce: :to_s, array: true
      end
    end

    it "converts a single value to an array" do
      instance = klass.new( tags: 'apple' )
      expect( instance.tags ).to eq ['apple']
    end

    it "coerces each item in the array" do
      instance = klass.new( tags: [:orange] )
      expect( instance.tags ).to eq ['orange']
    end
  end

  it "updates instance variable" do
    instance = base_klass.new
    instance.value = "abc"

    expect( instance.instance_variable_get( :@value ) ).to eq "abc"
  end

  it "calls assignment methods on assign_attributes" do
    klass = Class.new( base_klass ) do
      attribute :attr
    end

    expect_any_instance_of( klass ).to receive( :assign_attr )

    klass.new( attr: 1 )
  end

  describe "coercion" do
    it "coerces using given method name" do
      klass = Class.new( base_klass ) do
        attribute :count, coerce: :to_i
      end

      value = double
      expect( value ).to receive( :to_i ).and_return( 5 )

      instance = klass.new
      instance.count = value

      expect( instance.count ).to eq 5
    end

    it "coerces using given method proc" do
      klass = Class.new( base_klass ) do
        attribute :label, coerce: ->(_) { 'coerced' }
      end

      instance = klass.new( label: 'original' )
      expect( instance.label ).to eq 'coerced'
    end

    describe "smart" do
      let( :klass ) do
        Class.new( base_klass ) do
          attribute :updated_at
          attribute :expire_on

          attribute :user_id
          attribute :tag_ids
        end
      end
      let( :instance ) { klass.new }

      it "coerces nnn_at to timestamps" do
        value = double
        expect( value ).to receive( :to_datetime )

        instance.updated_at = value
      end

      it "coerces nnn_on to timestamps" do
        value = double
        expect( value ).to receive( :to_datetime )

        instance.expire_on = value
      end

      it "coerces nnn_id to an Integer" do
        value = double
        expect( value ).to receive( :to_i )

        instance.user_id = value
      end

      it "coerces nnn_ids to an array of Integers" do
        value = double
        expect( value ).to receive( :to_i )

        instance.tag_ids = value
      end

    end
  end

end