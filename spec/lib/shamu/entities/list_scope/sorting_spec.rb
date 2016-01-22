require "spec_helper"
require "shamu/entities"

describe Shamu::Entities::ListScope::Paging do
  let( :klass ) do
    Class.new( Shamu::Entities::ListScope ) do
      include Shamu::Entities::ListScope::Sorting
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

  it "is not sorted with defaults" do
    expect( klass.new.sorted? ).to be_falsy
  end

  it "is sorted when asked" do
    expect( klass.new( sort_by: :name ).sorted? ).to be_truthy
  end
end