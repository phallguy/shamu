# coding: utf-8
lib = File.expand_path( "../lib", __FILE__ )
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

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3.0"


  spec.add_dependency "activemodel", "~> 4.2"
  spec.add_dependency "activesupport", "~> 4.2"
  spec.add_dependency "scorpion-ioc", "~> 0.5.11"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "i18n", "~> 0.7"
  spec.add_development_dependency "rake", "~> 10"
  spec.add_development_dependency "rspec", "~> 3.00"
end
