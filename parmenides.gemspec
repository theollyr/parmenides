# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'parmenides/version'

Gem::Specification.new do |spec|
  spec.name          = "parmenides"
  spec.version       = Parmenides::VERSION
  spec.authors       = ["Patrik Gajdosik"]
  spec.email         = ["gajdosik.patrikk@gmail.com"]
  spec.summary       = %q{Tool for enabling of expansion of DBpedia.}
  spec.description   = %q{TOP SECRET}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "rdf"
  spec.add_runtime_dependency "sparql-client"
  spec.add_runtime_dependency "awesome_print"
  spec.add_runtime_dependency "configatron"
  spec.add_runtime_dependency "nokogiri"
  spec.add_runtime_dependency "rest-client"
end
