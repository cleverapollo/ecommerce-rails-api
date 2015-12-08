# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rees46_ml/version'

Gem::Specification.new do |spec|
  spec.name          = "rees46_ml"
  spec.version       = Rees46ML::VERSION
  spec.authors       = ["Andrey Zinenko"]
  spec.email         = ["azinenko@mkechinov.com"]
  spec.summary       = %q{Write a short summary, because Rubygems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  spec.homepage      = "http://rees46.com"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "nokogiri", ">= 1.6"
  spec.add_runtime_dependency "aasm", ">= 4.0"
  spec.add_runtime_dependency "virtus", ">= 1.0"
  spec.add_runtime_dependency "activemodel"

  spec.add_development_dependency "bundler", ">= 1.7"
  spec.add_development_dependency "rake",    ">= 10.0"
  spec.add_development_dependency "pry",     ">= 0.10.1"
  spec.add_development_dependency "rspec",   ">= 3.2"
  spec.add_development_dependency "rubocop", "~> 0.31.0"
  spec.add_development_dependency "builder", "~> 2.0"
  spec.add_development_dependency "stackprof"
end
