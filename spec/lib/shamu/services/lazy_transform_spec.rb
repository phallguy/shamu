require "spec_helper"

describe Shamu::Services::LazyTransform do
  let(:source) { [1, 2, 3] }

  def transformer
    lambda do |records|
      records.map do |r|
        yield
        r
      end
    end
  end

  it "short-circuits count" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      expect(transformed.count).to(eq(source.count))
    end.not_to(yield_control)
  end

  it "delegates when count has an arg" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      expect(transformed.count(1000)).to(eq(0))
    end.to(yield_control)
  end

  it "delegates when count has a block given" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      expect(transformed.count { true }).to(eq(source.count))
    end.to(yield_control)
  end

  it "short-circuits first" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      transformed.first
    end.to(yield_control.once)
  end

  it "doesn't short-circuit first(n)" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      transformed.first(2)
    end.to(yield_control.exactly(3))
  end

  it "short-circuits last" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      transformed.last
    end.to(yield_control.once)
  end

  it "doesn't short-circuit last(n)" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      transformed.last(2)
    end.to(yield_control.exactly(3))
  end

  it "short-circuits empty?" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      expect(transformed).not_to(be_empty)
    end.not_to(yield_control)
  end

  it "short-circuits present?" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      transformed.present?
    end.not_to(yield_control)
  end

  it "transforms when enumerated" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      transformed.to_a
    end.to(yield_control.exactly(3))
  end

  it "yields transformed values" do
    transformed = Shamu::Services::LazyTransform.new(source) { |vs| vs.map { |v| v * v } }
    expect(transformed.to_a).to(eq([1, 4, 9]))
  end

  it "short-circuits drop" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      transformed.drop(2).to_a
    end.to(yield_control.exactly(1))
  end

  it "uses existing transformed on drop if avaialable" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      transformed.to_a
      transformed.drop(2).to_a
    end.to(yield_control.exactly(3))
  end

  it "short-circuits take" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      transformed.take(2).to_a
    end.to(yield_control.exactly(2))
  end

  it "users existing transformed on take if avaialable" do
    expect do |block|
      transformed = Shamu::Services::LazyTransform.new(source, &transformer(&block))
      transformed.to_a
      transformed.take(2).to_a
    end.to(yield_control.exactly(3))
  end
end
