RSpec::Matchers.define(:raise_access_denied) do |_expected|
  def supports_block_expectations?
    true
  end

  match do |actual|
    begin
      subject && subject.stub(:access_denied) do |exception|
        raise exception
      end

      actual.call
      false
    rescue CanCan::AccessDenied
      true
    rescue Services::Security::AccessDeniedError
      true
    end
    false
  end
end

RSpec::Matchers.define(:be_permitted_to) do |*args|
  def supports_block_expectations?
    true
  end

  failure_message do
    "be permitted to #{expected.first} #{expected.second.inspect}"
  end

  description do
    "be permitted to #{expected.first} #{expected.second.inspect}"
  end

  match do |policy|
    policy.permit?(*args)
  end
end

RSpec::Matchers.define(:maybe_be_permitted_to) do |*args|
  def supports_block_expectations?
    true
  end

  failure_message do
    "maybe be permitted to #{expected.first} #{expected.second.inspect}"
  end

  description do
    "maybe be permitted to #{expected.first} #{expected.second.inspect}"
  end

  match do |policy|
    policy.permit?(*args) == :maybe
  end
end

RSpec::Matchers.define(:absolutely_be_permitted_to) do |*args|
  def supports_block_expectations?
    true
  end

  failure_message do
    "absolutely be permitted to #{expected.first} #{expected.second.inspect}"
  end

  description do
    "absolutely be permitted to #{expected.first} #{expected.second.inspect}"
  end

  match do |policy|
    policy.permit?(*args) == :yes
  end
end
