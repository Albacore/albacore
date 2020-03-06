# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require 'albacore/version'

Gem::Specification.new do |s|
  s.name        = 'albacore'
  s.version     = Albacore::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Henrik Feldt', 'Anthony Mastrean']
  s.email       = 'henrik@haf.se'
  s.homepage    = 'http://albacorebuild.net'
  s.summary     = 'Dolphin-safe and awesome Mono and .Net Rake-tasks'
  s.license     = 'MIT'
  s.description = <<-EOF
    Easily build your .Net or Mono project using this collection of Rake tasks.
    Albacore assist you in creating nugets, managing nugets, building your projects,
    handling the .Net compilers while making it very easy to integrate your ruby-code
    with existing dev-ops tools, such as Puppet, Chef, Capistrano or Vagrant/VirtualBox.
EOF

  s.rubyforge_project = 'albacore'

  s.add_dependency 'rake', '~> 12' # this gem builds on rake
  s.add_dependency 'map', '~> 6.5' # https://github.com/ahoward/map for options handling
  s.add_dependency 'nokogiri', '~> 1.5' # used to manipulate and read *proj files
  s.add_dependency 'semver2', '~> 3.4'
	
  s.add_development_dependency 'rubygems-tasks', '~>0.2'
  s.add_development_dependency 'rspec', '~> 3.00'
  s.add_development_dependency 'nuget', '~> 2.8'

  s.files         = Dir.glob './{lib,resources}/**/*'
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename f }
  s.require_paths = %w|bin lib|
end
