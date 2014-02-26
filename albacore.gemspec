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

  s.add_dependency 'rake', '>10' # this gem builds on rake
  s.add_dependency 'map', '~>6.5' # https://github.com/ahoward/map for options handling
  s.add_dependency 'nokogiri', '~> 1.5' # used to manipulate and read *proj files
  s.add_dependency 'facter', '~> 1.7' # used to gather system data
  s.add_dependency 'semver2', '~> 3.3'
  s.add_dependency 'ProcessPilot', '~> 2.0'
  s.add_dependency 'highline', '~> 1.6'
	
  s.add_development_dependency 'rubygems-tasks', '~>0.2'
  s.add_development_dependency 'rspec', '>= 2.13'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  # s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
