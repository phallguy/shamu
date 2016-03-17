
RSpec::Matchers.define :be_permitted_to do |*args|

  def supports_block_expectations?
    true
  end

  failure_message do |actual|
    "expected that #{ actual.class.name } would be permitted to #{ expected.first } #{ expected.second }"
  end
  match do |policy|
    policy.permit?( *args )
  end
end

RSpec::Matchers.define :maybe_be_permitted_to do |*args|

  def supports_block_expectations?
    true
  end

  failure_message do |actual|
    "expected that #{ actual.class.name } might be permitted to #{ expected.first } #{ expected.second }"
  end

  match do |policy|
    policy.permit?( *args ) == :maybe
  end
end

RSpec::Matchers.define :absolutely_be_permitted_to do |*args|

  def supports_block_expectations?
    true
  end

  failure_message do |actual|
    "expected that #{ actual.class.name } would absolutely be permitted to #{ expected.first } #{ expected.second }"
  end

  match do |policy|
    policy.permit?( *args ) == :yes
  end
end