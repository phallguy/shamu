require "spec_helper"
require "shamu/entities"

describe Shamu::Entities::ListScope do

  let( :klass ) do
    Class.new( Shamu::Entities::ListScope ) do
      def self.validates( * ); end

      attribute :name, presence: true
    end
  end

  describe ".coerce" do
    it "coerces an instance of the scope to self" do
      scope = klass.new
      expect( klass.coerce( scope ) ).to be scope
    end

    it "coerces a hash" do
      expect( klass.coerce( {} ) ).to be_a klass
    end

    it "coerces a nil" do
      expect( klass.coerce( nil ) ).to be_a klass
    end

    it "raises ArgumentError on other values" do
      expect do
        klass.coerce( "" )
      end.to raise_error ArgumentError
    end
  end

  describe ".coerce!" do
    it "raises ArgumentError if the scope has invalid params" do
      scope = klass.new( name: nil )
      expect( scope ).to receive( :valid? ).and_return false

      expect do
        klass.coerce!( scope )
      end.to raise_error ArgumentError
    end

    it "returns the scope if the params are valid" do
      scope = klass.new( name: nil )
      expect( scope ).to receive( :valid? ).and_return true

      expect do
        klass.coerce!( scope )
      end.not_to raise_error
    end
  end

  describe "#except" do
    it "excludes the requested params" do
      instance = klass.new( name: "Orca" )
      expect( instance.except( :name ).name ).to be_nil
    end

    it "returns an instance of the same class" do
      instance = klass.new( name: "Killer" )
      expect( instance.except ).to be_a klass
    end
  end

  describe ".paging" do
    let( :klass ) do
      Class.new( Shamu::Entities::ListScope ) do
        paging
      end
    end

    it "has a :page attribute" do
      expect( klass.attributes ).to have_key :page
    end

    it "has a :page_size attribute" do
      expect( klass.attributes ).to have_key :page_size
    end

    it "has a :default_page_size" do
      expect( klass.attributes ).to have_key :default_page_size
    end

    it "uses default_page_size if not page_size set" do
      expect( klass.new.page_size ).to eq 25
    end

    it "includes paging values in to_param" do
      expect( klass.new.to_param ).to eq page: 1, page_size: 25
    end
  end

  describe ".scoped_paging" do
    let( :klass ) do
      Class.new( Shamu::Entities::ListScope ) do
        scoped_paging
      end
    end

    it "has a :page attribute" do
      expect( klass.attributes ).to have_key :page
    end

    it "has a :page.number attribute" do
      expect( klass.new.page.class.attributes ).to have_key :number
    end

    it "has a :page.size attribute" do
      expect( klass.new.page.class.attributes ).to have_key :size
    end

    it "has a :page.default_size attribute" do
      expect( klass.new.page.class.attributes ).to have_key :default_size
    end

    it "includes paging values in to_param" do
      expect( klass.new.to_param ).to eq page: { number: 1, size: 25 }
    end
  end

  describe ".dates" do
    let( :klass ) do
      Class.new( Shamu::Entities::ListScope ) do
        dates
      end
    end

    it "has a :since attribute" do
      expect( klass.attributes ).to have_key :since
    end

    it "has an :until attribute" do
      expect( klass.attributes ).to have_key :until
    end

    it "coerces with #to_time if available" do
      expect( Time ).to receive( :instance_method ).and_return( true )
      value = double
      expect( value ).to receive( :to_time )

      klass.new( since: value )
    end

    it "includes paging values in to_param" do
      time = Time.now
      expect( klass.new( since: time, until: time ).to_param ).to eq since: time, until: time
    end
  end

  describe ".sorting" do
    let( :klass ) do
      Class.new( Shamu::Entities::ListScope ) do
        sorting
      end
    end

    it "parses single values" do
      scope = klass.new( sort_by: :first_name )
      expect( scope.sort_by ).to eq first_name: :asc
    end

    it "parses array of values" do
      scope = klass.new( sort_by: [ :first_name, :last_name ] )
      expect( scope.sort_by ).to eq first_name: :asc, last_name: :asc
    end

    it "parses array of args to fluid_assignment" do
      scope = klass.new
      scope.sort_by :first_name, :last_name
      expect( scope.sort_by ).to eq first_name: :asc, last_name: :asc
    end

    it "parses array via assignment" do
      scope = klass.new
      scope.sort_by = [ :first_name, :last_name ]
      expect( scope.sort_by ).to eq first_name: :asc, last_name: :asc
    end

    it "parses hash" do
      scope = klass.new sort_by: { first_name: :desc }
      expect( scope.sort_by ).to eq first_name: :desc
    end

    it "parses array with hash" do
      scope = klass.new sort_by: [{ last_name: :desc }]
      expect( scope.sort_by ).to eq last_name: :desc
    end

    it "parses hash with array" do
      scope = klass.new sort_by: { campaign: [ :created_at ] }
      expect( scope.sort_by ).to eq campaign: { created_at: :asc }
    end

    it "includes sorting values in to_param" do
      expect( klass.new( sort_by: :name ).to_param ).to eq sort_by: { name: :asc }
    end
  end

end