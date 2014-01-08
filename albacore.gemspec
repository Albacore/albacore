# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "albacore/version"

Gem::Specification.new do |spec|
  spec.name          = "albacore"
  spec.version       = Albacore::VERSION
  spec.authors       = ["Henrik Feldt", "Anthony Mastrean", "Derick Bailey"]
  spec.email         = ["albacorebuild@gmail.com"]
  spec.description   = %q{Albacore is a professional quality suite of Rake tasks for building .NET or Mono based systems.}
  spec.summary       = %q{Dolphin-safe .NET and Mono rake tasks}
  spec.homepage      = "http://albacorebuild.net"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.5"
  spec.add_dependency "rake"
  spec.add_dependency "rubyzip", "~> 1.0"

  spec.add_development_dependency "rspec"

  spec.rubyforge_project = "albacore"
end
