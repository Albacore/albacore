# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require 'albacore'

Gem::Specification.new do |s|
  s.name        = 'albacore'
  s.version     = Albacore::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Henrik Feldt', 'Anthony Mastrean']
  s.email       = 'henrik@haf.se'
  s.homepage    = 'http://albacorebuild.net'
  s.summary     = 'Dolphin-safe and awesome Mono and .Net Rake-tasks'
  s.description = <<-EOF
    Easily build your .Net or Mono project using this collection of Rake tasks.
    Albacore assist you in creating nugets, managing nugets, building your projects,
    handling the .Net compilers while making it very easy to integrate your ruby-code
    with existing dev-ops tools, such as Puppet, Chef, Capistrano or Vagrant/VirtualBox.
EOF

  s.rubyforge_project = 'albacore'
  
  s.add_dependency 'rake', '~>10.0.2' # this gem builds on rake
  s.add_dependency 'map', '~>6.2.0' # https://github.com/ahoward/map for options handling
  s.add_dependency 'nokogiri', '~>1.5.6' # used to manipulate and read *proj files
  
  s.add_development_dependency 'rubygems-tasks', '~>0.2.3'
  s.add_development_dependency 'guard', '~>1.6.1'
  s.add_development_dependency 'guard-rspec', '~>2.3.3'
  s.add_development_dependency 'rspec', '~>2.12.0'
  s.add_development_dependency 'vagrant', '~>1.0.5'
  s.add_development_dependency 'vagrant-vbguest', '~>0.5.1'
  s.add_development_dependency 'bundler', '~>1.2.3'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  # s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end