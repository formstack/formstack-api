# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'formstack/api/version'

Gem::Specification.new do |spec|
  spec.name          = "formstack-api"
  spec.version       = Formstack::Api::VERSION
  spec.authors       = ["Mauro Morales"]
  spec.email         = ["contact@mauromorales.com"]
  spec.summary       = %q{Formstack API V2 Ruby Wrapper.}
  spec.description   = %q{Ruby Formstack API V2 Ruby Wrapper based on https://github.com/formstack/formstack-api/tree/master/php.}
  spec.homepage      = "https://github.com/LAS-IT/formstack-api"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'httparty', '~> 0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'guard', '~> 2.6'
  spec.add_development_dependency 'guard-rspec', '~> 4.3'
  spec.add_development_dependency 'vcr', '~> 2.9'
  spec.add_development_dependency 'webmock', '~> 1.18'
end
