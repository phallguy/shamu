lib = File.expand_path( "lib", __dir__ )
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "shamu/version"

Gem::Specification.new do |spec|
  spec.name          = "shamu"
  spec.version       = Shamu::VERSION
  spec.authors       = [ "Paul Alexander" ]
  spec.email         = [ "me@phallguy.com" ]
  spec.summary       = "Have a whale of a good time adding Service Oriented Architecture to your ruby projects."
  spec.homepage      = "https://github.com/phallguy/shamu"
  spec.license       = "MIT"

  spec.files = Dir["lib/**/*.rb"] + Dir["bin/*"]
  spec.files += Dir["[A-Z]*"] + Dir["spec/**/*"]
  spec.files.reject! { |fn| fn.include? ".git" }

  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.6.0"

  spec.add_dependency "activemodel", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "crc32", "~> 1"
  # spec.add_dependency "listen", "~> 3"
  spec.add_dependency "loofah", "~> 2"
  spec.add_dependency "multi_json", "~> 1.11"
  spec.add_dependency "rack", ">= 1"
  spec.add_dependency "scorpion-ioc", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "combustion"
  spec.add_development_dependency "i18n"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
