require "spec_helper"
require "shamu/attributes"

describe Shamu::Attributes::Assignment do
  let( :base_klass ) do
    Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::Assignment

      attribute :value
    end
  end

  describe "arrays" do
    let( :klass ) do
      Class.new( base_klass ) do
        attribute :tags, coerce: :to_s, array: true
      end
    end

    it "converts a single value to an array" do
      instance = klass.new( tags: "apple" )
      expect( instance.tags ).to eq ["apple"]
    end

    it "coerces each item in the array" do
      instance = klass.new( tags: [:orange] )
      expect( instance.tags ).to eq ["orange"]
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

  it "creates aliased assignment" do
    klass = Class.new do
      include Shamu::Attributes
      include Shamu::Attributes::Assignment

      attribute :q, as: :query
    end

    instance = klass.new
    instance.query = "ABC"
    expect( instance.q ).to eq "ABC"
  end

  describe "#assigned_attributes" do
    let( :klass ) do
      Class.new do
        include Shamu::Attributes
        include Shamu::Attributes::Assignment

        attribute :name
        attribute :email
      end
    end

    it "identifies attributes assigned in constructor" do
      instance = klass.new name: "set"

      expect( instance.assigned_attributes ).to include :name
      expect( instance.assigned_attributes ).not_to include :email
      expect( instance.unassigned_attributes ).to include :email
    end

    it "does not identity attributes memoized by reading" do
      instance = klass.new name: "set"

      expect( instance.email ).to be_nil
      expect( instance.assigned_attributes ).to include :name
      expect( instance.assigned_attributes ).not_to include :email
      expect( instance.set?( :email ) ).to be_truthy
    end

    it "identifies attributes assigned explicitly" do
      instance = klass.new
      instance.name = "set"

      expect( instance.assigned_attributes ).to include :name
      expect( instance.assigned_attributes ).not_to include :email
    end

    it "identifies attribute_assigned?" do
      instance = klass.new name: "set"
      expect( instance.name_assigned? ).to be_truthy
    end
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
        attribute :label, coerce: ->(_) { "coerced" }
      end

      instance = klass.new( label: "original" )
      expect( instance.label ).to eq "coerced"
    end

    it "coerces using given attribute block" do
      klass = Class.new( base_klass ) do
        attribute :label do |_value|
          "coerced"
        end
      end

      instance = klass.new( label: "original" )
      expect( instance.label ).to eq "coerced"
    end

    it "handles attribute block when not initialized" do
      klass = Class.new( base_klass ) do
        attribute :label do |_value|
          "coerced"
        end
      end

      instance = klass.new
      expect( instance.label ).to eq nil
    end

    it "coerces using a class" do
      coerce_class = Class.new do
        def initialize( v ); end
      end

      klass = Class.new( base_klass ) do
        attribute :label, coerce: coerce_class
      end

      instance = klass.new( label: "original" )
      expect( instance.label ).to be_a coerce_class
    end

    describe "smart" do
      let( :klass ) do
        Class.new( base_klass ) do
          attribute :updated_at
          attribute :expire_on

          attribute :user_id
          attribute :tag_ids
          attribute :id
        end
      end
      let( :instance ) { klass.new }

      it "coerces nnn_at to timestamps" do
        value = double
        expect( value ).to receive( :to_time )

        instance.updated_at = value
      end

      it "coerces nnn_on to timestamps" do
        value = double
        expect( value ).to receive( :to_time )

        instance.expire_on = value
      end

      it "coerces nnn_id to a model id" do
        value = double
        expect( value ).to receive( :to_model_id )

        instance.user_id = value
      end

      it "coerces id to a model id" do
        value = double
        expect( value ).to receive( :to_model_id )

        instance.id = value
      end

      it "coerces nnn_ids to an array o model ids" do
        value = double
        expect( value ).to receive( :to_model_id )

        instance.tag_ids = value
      end

    end
  end

end
