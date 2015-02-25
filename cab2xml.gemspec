# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cab2xml/version'

Gem::Specification.new do |spec|
  spec.name          = "cab2xml"
  spec.version       = Cab2xml::VERSION
  spec.authors       = ["Mizuho IMADA"]
  spec.email         = ["imadamizuho@gmail.com"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = ""
  end

  spec.summary       = %q{Cabocha to XML.}
  spec.description   = %q{Cabocha to XML.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
#  spec.bindir        = "exe"
#  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.bindir        = "lib"
  spec.executables   = ["cab2xml"]
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
end
