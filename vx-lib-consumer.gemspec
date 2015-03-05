# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vx/lib/consumer/version'

Gem::Specification.new do |spec|
  spec.name          = "vx-lib-consumer"
  spec.version       = Vx::Lib::Consumer::VERSION
  spec.authors       = ["Dmitry Galinsky"]
  spec.email         = ["dima.exe@gmail.com"]
  spec.summary       = %q{ summary }
  spec.description   = %q{ description }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'bunny',               '= 1.7.0'
  spec.add_runtime_dependency 'vx-lib-rack-builder', '>= 0.0.2'
  spec.add_runtime_dependency 'oj'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", '2.14.1'
end
