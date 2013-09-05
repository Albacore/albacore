# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "albacore/version"

Gem::Specification.new do |s|
  s.name        = "albacore"
  s.version     = Albacore::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Henrik Feldt", "Anthony Mastrean"]
  s.email       = "albacorebuild@gmail.com"
  s.homepage    = "http://albacorebuild.net"
  s.summary     = "Dolphin-safe .NET and Mono rake tasks"
  s.description = "Albacore is a professional quality suite of Rake tasks for building .NET or Mono based systems."

  s.add_dependency "nokogiri", "~> 1.5"
  s.add_dependency "rake"
  s.add_dependency "rubyzip", "< 1.0.0"

  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "rspec"

  s.rubyforge_project = "albacore"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths = ["lib"]
end
