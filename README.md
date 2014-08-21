# Albacore v2.0

[![Version     ](https://img.shields.io/gem/v/albacore.svg?style=flat)](https://rubygems.org/gems/albacore)
[![Build Status](http://img.shields.io/travis/Albacore/albacore/master.svg?style=flat)](http://travis-ci.org/Albacore/albacore)
[![Gittip      ](http://img.shields.io/gittip/haf.svg?style=flat)](http://gittip.com/haf)
[![Code Climate](https://img.shields.io/codeclimate/github/Albacore/albacore.svg?style=flat)](https://codeclimate.com/github/albacore/albacore)

Albacore is a suite of tools for the professional .Net or mono developer that
make their life easier.

    gem install albacore

## Main Features

 - Runs .Net and mono builds on OS X, Windows and Linux quick and painless
 - Manage xbuild/msbuild transparently
 - NuGet restore without intrusive .nuget target files in your project files,
   authentication supported
 - NuGet pack task types for packaging your code, supports packaging
   symbols/source and custom nuspecs, getting metadata from context
 - Declarative Rake syntax makes it easy to read Rakefiles
 - Most tasks, including the NuGet tasks accept an array of csproj- or fsproj-
   files and act on all those projects, discovering metadata from their XML.
 - An improved set APIs for calling operating system processes and managing them
   from the build script (see DSL below)
 - Quick and easy to turn on debugging, just set the DEBUG env var
 - Assembly version generation in C#, F#, C++ and VB
 - A copy-local test-runner for those of you with Parallels/Fusion needing to
   shadow-copy assemblies from a 'network drive'
 - An innovative `.appspec` file lets you construct IIS Site-packages with
   Chocolatey on Windows, Topshelf services with Chocolatey on Windows and RPM
   and DEB services on Linux with three lines of code - become the DevOps GOD of
   your company!
 - Transparent publish of artifacts to TeamCity with the TC extension
 - Unit tested, high quality Ruby code
 - Actively developed by Henrik Feldt, Software Architect at
   [Intelliplan](http://intelliplan.se) - there's someone looking after the
   code. We're active and taking pull requests - an open source project is not a
   single-person game, but it's nice to have some stability.

The [wiki](https://github.com/Albacore/albacore/wiki) is the main reference for
the above task types, but there's also [very
extensive](http://rubydoc.info/gems/albacore/2.0.0/frames) documentation in the
code, as well as hundreds of unit tests written in a easy-to-read rspec syntax.

## Getting Started

Follow along for a quick intro, but if on Windows, see the section 'Installing
Ruby' first. Albacore works on both Ruby 1.9.3 and 2.x.

First create `Gemfile` with these contents:

    source 'https://rubygems.org'
    gem 'albacore', '2.0.0'

When setting up your build you need to ensure it is reproducible.  Bundler
allows you to lock down the few gems that Albacore depend on to their specific
versions, ensuring that your peers can re-run the same build script you just
built and that it works well on your continous integration server.

Now you can bundle the dependencies, effectively freezing all gem dependencies
that your build depends on.

    bundle install
    git add Gemfile
    git add Gemfile.lock
    git commit -m 'Installed Albacore'

Now you are ready to continue reading below for your first Rakefile.

### Installing Ruby on Windows

Install [Chocolatey](http://chocolatey.org) by, in a command prompt, running:

    @powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('http://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%systemdrive%\chocolatey\bin

Then start a new powershell, cygwin or mingw32 shell. You can now install the
Ruby framework:

    cinst ruby.devkit

Now, restart your shell or reload its path variable. You now have rake
installed. Now you can install Albacore, the collection of tasktypes, tasks and
extension points aimed to make your life as a .Net developer easier:

    gem install bundler

Continue below with your first Rakefile.

## Creating Your First Rakefile

In order to build your project, you need to create a `Rakefile`, with contents
like these:

``` ruby
require 'bundler/setup'

require 'albacore'
require 'albacore/tasks/versionizer'
require 'albacore/ext/teamcity'

Albacore::Tasks::Versionizer.new :versioning

desc 'Perform fast build (warn: doesn\'t d/l deps)'
build :quick_build do |b|
  b.logging = 'detailed'
  b.sln     = 'src/MyProj.sln'
end

desc 'restore all nugets as per the packages.config files'
nugets_restore :restore do |p|
  p.out = 'src/packages'
  p.exe = 'tools/NuGet.exe'
end

desc 'Perform full build'
build :build => [:versioning, :restore] do |b|
  b.sln = 'src/MyProj.sln'
  # alt: b.file = 'src/MyProj.sln'
end

directory 'build/pkg'

desc 'package nugets - finds all projects and package them'
nugets_pack :create_nugets => ['build/pkg', :versioning, :build] do |p|
  p.files   = FileList['src/**/*.{csproj,fsproj,nuspec}'].
    exclude(/Tests/)
  p.out     = 'build/pkg'
  p.exe     = 'buildsupport/NuGet.exe'
  p.with_metadata do |m|
    m.description = 'A cool nuget'
    m.authors = 'Henrik'
    m.version = ENV['NUGET_VERSION']
  end
  p.with_package do |p|
    p.add_file 'file/relative/to/proj', 'lib/net40'
  end
end

task :default => :create_nugets
```

You can now run:

    bundle exec rake

## Contributing

 1. Create a feature branch with your change:
    a. With unit test
    b. With feature
 1. Send a PR with that feature branch to this branch
    a. Make sure TravisCI is OK with it
    b. Describe your PR in English.

## Writing Code

 1. Add a rspec spec in specs/
 1. Run `bundle exec rspec spec` to verify test fails
 1. Implement feature you want
 1. Run the tests again, have them pass
 1. Make a PR from your feature branch against `master`

Document your code with
[YARD](http://rubydoc.info/gems/yard/file/docs/GettingStarted.md) as you're
writing it: it's much easier to write the documentation together with the code
than afterwards.

