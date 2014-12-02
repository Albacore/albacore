# Albacore v2.0
[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/Albacore/albacore?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

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
 - Actively developed by [@haf](https://github.com/haf)

The [wiki](https://github.com/Albacore/albacore/wiki) is the main reference for
the above task types, but there's also [very
extensive](http://rubydoc.info/gems/albacore/2.0.0/frames) documentation in the
code, as well as hundreds of unit tests written in a easy-to-read rspec syntax.

## Quickstart TLDR; SHOW ME THE CODE!

    gem install albacore
    albacore init

Now you have the initial setup and can run `bundle exec rake`. But please read
below:

## Getting Started

Follow along for a quick intro, but if on Windows, see the section 'Installing
Ruby' first. Albacore works on both Ruby 1.9.3 and 2.x.

First create `Gemfile` with these contents:

    source 'https://rubygems.org'
    gem 'albacore', '~> 2.0.0'

When setting up your build you need to ensure it is reproducible.  Bundler
allows you to lock down the few gems that Albacore depend on to their specific
versions, ensuring that your peers can re-run the same build script you just
built and that it works well on your continous integration server.

Now you can bundle the dependencies, effectively freezing all gem dependencies
that your build depends on.

    bundle
    git add Gemfile*
    git commit -m 'Installed Albacore'

Now you are ready to continue reading below for your first Rakefile.

### Installing Ruby on Windows

First install Ruby from http://rubyinstaller.org/downloads/ - e.g. [v2.1.3
32-bits](http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.1.3.exe?direct)
which is the latest version, at time of writing.

Second, install Ruby DevKit, or you won't be able to install nokogiri. Download
it [lower down on the same
page](http://cdn.rubyinstaller.org/archives/devkits/DevKit-mingw64-32-4.7.2-20130224-1151-sfx.exe),
open a console:

``` bash
cd \DevKit
ruby dk.rb init
ruby dk.rb install
```

Now close that console and open a new console, and run:

    gem install bundler

This gives you a working ruby installation. Continue below with your first
Rakefile.

You can also try [chocolatey](https://chocolatey.org/packages/ruby) and [ruby2.devkit](https://chocolatey.org/packages/ruby2.devkit).

### Installing Ruby on OS X

``` bash
brew install rbenv ruby-build
rbenv install 2.1.3
gem install bundler
```

Done. Ensure `brew doctor` is clean enough and that `ruby --version` outputs the
expected version.

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
  p.exe     = 'tools/NuGet.exe'
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

You can continue reading about the available task-types in [the wiki][wiki].

If you're upgrading from v1.0, there's an article [there for you][upgrade-v1.0]

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

 [wiki]: https://github.com/Albacore/albacore/wiki
 [upgrade-v1.0]: https://github.com/Albacore/albacore/wiki/Upgrading-from-v1.0
