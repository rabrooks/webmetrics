# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'webmetrics/version'

Gem::Specification.new do |spec|
  spec.name          = "webmetrics"
  spec.version       = Webmetrics::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Aaron Brooks"]
  spec.email         = ["aaronbrooks322@gmail.com"]
  spec.description   = "Helps track user lifecycle metrics via MongoDB. It also provides reporting tools and grouping options."
  spec.summary       = "Track website metrics"
  spec.homepage      = "https://github.com/rabrooks/web-metrics"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  #spec.rubyforge_project = "webmetrics"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "rack", "~> 1.5.2"
  spec.add_runtime_dependency "mongo", "~> 1.9.2"
  spec.add_runtime_dependency "activesupport", "~> 4.0.0"


end