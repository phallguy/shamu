require "spec_helper"
require "shamu/attributes"

describe Shamu::Attributes do
  let(:klass) do
    Class.new do
      include Shamu::Attributes

      attribute :name
      attribute :info, on: :contact
      attribute :contact
      attribute :company, default: "ACME"

      public :set?
    end
  end

  it "uses instance variables" do
    instance = klass.new(name: "Example")

    expect(instance.instance_variable_get(:@name)).to(eq("Example"))
  end

  it "uses second optional arg as builder if present" do
    builder = double
    expect(builder).to(receive(:call))

    klass = Class.new do
      include Shamu::Attributes

      attribute :address, builder
    end

    klass.new(address: {})
  end

  it "uses block as builder if present" do
    expect do |b|
      klass = Class.new do
        include Shamu::Attributes

        attribute :address, &b
      end

      klass.new(address: {}).address
    end.to(yield_control)
  end

  it "creates alias accessor" do
    klass = Class.new do
      include Shamu::Attributes

      attribute :q, as: :query
    end

    expect(klass.new).to(respond_to(:query))
  end

  describe "#set?" do
    it "is true if the attribute has been set" do
      expect(klass.new(name: "Set")).to(be_set(:name))
    end

    it "is true if the attribute has been set to nil" do
      expect(klass.new(name: nil)).to(be_set(:name))
    end

    it "is false if the attribute has not been set" do
      expect(klass.new).not_to(be_set(:name))
    end

    it "has per attribute set? method" do
      expect(klass.new(name: "Set").name_set?).to(be_truthy)
    end
  end

  describe "delegate" do
    it "delegates to another method" do
      contact = double
      expect(contact).to(receive(:info))

      instance = klass.new(contact: contact)
      instance.info
    end

    it "returns nil if delegate is nil" do
      expect(klass.new(contact: nil).info).to(be_nil)
    end

    it "fetches value only once" do
      contact = double
      expect(contact).to(receive(:info) { Time.now.to_f })

      instance = klass.new(contact: contact)
      time = instance.info
      sleep 0.1
      expect(instance.info).to(eq(time))
    end

    it "uses builder on result" do
      builder = double
      expect(builder).to(receive(:call) { |v| v })

      klass = Class.new do
        include Shamu::Attributes

        attribute :contact
        attribute :address, builder, on: :contact
      end

      contact = double
      attrs = double
      expect(contact).to(receive(:address).and_return(attrs))

      instance = klass.new(contact: contact)
      instance.address
    end
  end

  context "with block" do
    let(:klass) do
      Class.new do
        include Shamu::Attributes

        attribute :time do
          Time.now.to_f
        end
      end
    end

    it "uses a block if provided" do
      expect(klass.new.time).to(be_a(Float))
    end

    it "computes value once" do
      instance = klass.new
      time = instance.time
      sleep 0.1
      expect(instance.time).to(eq(time))
    end
  end

  describe "defaults" do
    it "uses default if not set" do
      expect(klass.new({}).company).to(eq("ACME"))
    end

    it "are overriden with a nil value" do
      expect(klass.new(company: nil).company).to(be_nil)
    end

    it "doesn't use any default if not defined" do
      expect(klass.new({}).name).to(be_nil)
    end

    it "invokes default function if provided" do
      klass = Class.new do
        include Shamu::Attributes

        attribute :version
        attribute :opened, default: -> { version > 5 }
      end

      instance = klass.new(version: 18)
      expect(instance.opened).to(be_truthy)
    end
  end

  describe "inheritance" do
    let(:parent) do
      Class.new do
        include Shamu::Attributes

        attribute :name
      end
    end

    let(:child) do
      Class.new(parent) do
        attribute :email
      end
    end

    it "inherits parent attributes" do
      expect(child.attributes).to(have_key(:name))
      expect(child.attributes).to(have_key(:email))
    end

    it "does not modify parent attributes" do
      expect(parent.attributes).not_to(have_key(:email))
    end
  end

  describe "#assign_attributes" do
    let(:klass) do
      nested = nested_klass
      Class.new do
        include Shamu::Attributes

        attribute :name
        attribute :contact, build: nested
      end
    end

    let(:nested_klass) do
      Class.new do
        include Shamu::Attributes

        attribute :email
      end
    end

    it "invokes assign_nnn for each value" do
      expect_any_instance_of(klass).to(receive(:assign_name))

      klass.new(name: "something")
    end

    it "assigns nested attributes" do
      instance = klass.new(contact: { email: "batman@gotham.com" })

      expect(instance.contact.email).to(eq("batman@gotham.com"))
    end

    it "builds using custom builder" do
      builder = double
      expect(builder).to(receive(:call).with(kind_of(Hash))) do |attrs|
        nested_klass.new(attrs)
      end

      klass = Class.new do
        include Shamu::Attributes

        attribute :nested, build: builder
      end

      klass.new(nested: {})
    end

    it "coerces objects that respond to to_attributes" do
      attrs = double
      expect(attrs).to(receive(:to_attributes).and_return({}))

      klass.new(attrs)
    end

    it "coerces objects that respond to to_h" do
      attrs = double
      expect(attrs).to(receive(:to_h).and_return({}))

      klass.new(attrs)
    end

    it "handles nil" do
      expect do
        klass.new(nil)
      end.not_to(raise_error)
    end

    it "accepts alias key" do
      klass = Class.new do
        include Shamu::Attributes

        attribute :q, as: :query
      end

      expect(klass.new(query: "ABC").q).to(eq("ABC"))
    end

    it "fails for unknown attributes" do
      klass = Class.new do
        include Shamu::Attributes

        attribute :named
      end

      expect do
        klass.new(not_a_real_attribute: true)
      end.to(raise_error(Shamu::Attributes::UnknownAttributeError))
    end

    it "ignores unknown attributes fro rails request params" do
      klass = Class.new do
        include Shamu::Attributes

        attribute :named
      end

      expect do
        params = {}
        params[:not_a_real_attribute] = true
        def params.permit; end

        klass.new(params)
      end.not_to(raise_error)
    end
  end

  describe "#to_attributes" do
    let(:klass) do
      Class.new do
        include Shamu::Attributes
        include Shamu::Attributes::Assignment

        attribute :user, serialize: false

        attribute :name, on: :user
        attribute :email, on: :user
      end
    end

    let(:user)     { OpenStruct.new(name: "Heisenberg", email: "blue@rock.com") }
    let(:instance) { klass.new(user: user) }

    subject { instance.to_attributes }

    it { is_expected.to(have_key(:name)) }
    it { is_expected.to(have_key(:email)) }
    it { is_expected.not_to(have_key(:user)) }

    it "includes only requested attributes array" do
      attrs = instance.to_attributes(only: :name)

      expect(attrs).to(have_key(:name))
      expect(attrs).not_to(have_key(:email))
    end

    it "includes only requested attributes regex" do
      attrs = instance.to_attributes(only: /email/)

      expect(attrs).not_to(have_key(:name))
      expect(attrs).to(have_key(:email))
    end

    it "excludes requested attributes array" do
      attrs = instance.to_attributes(except: :name)

      expect(attrs).not_to(have_key(:name))
      expect(attrs).to(have_key(:email))
    end

    it "excludes requested attributes regex" do
      attrs = instance.to_attributes(except: /email/)

      expect(attrs).to(have_key(:name))
      expect(attrs).not_to(have_key(:email))
    end

    it "can be used to clone the entity" do
      instance = klass.new(name: "Peter", email: "parker@marvel.com")
      clone    = klass.new(instance)

      expect(clone.name).to(eq("Peter"))
    end

    it "invokes to_attributes of nested attributes" do
      user.name = double
      expect(user.name).not_to(receive(:to_attributes))

      instance.to_attributes
    end
  end

  describe "Hash like access" do
    it "recognizes known attributes" do
      expect(klass.new.key?(:name)).to(be_truthy)
    end

    it "retrieves attribute values by name" do
      expect(klass.new(name: "Example")["name"]).to(eq("Example"))
    end
  end
end
