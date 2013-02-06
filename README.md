# Albacore Clean Slate

[![Build Status](https://secure.travis-ci.org/Albacore/albacore.png?branch=clean_slate)](http://travis-ci.org/Albacore/albacore)
[![Dependency Status](https://gemnasium.com/Albacore/albacore.png)](https://gemnasium.com/Albacore/albacore)

This branch is where I try to rebuild albacore from the ground up. Initially I
am targeting my own closed-source project and extracting tasks and patterns as I
go.

Henrik

## getting started

In a command prompt, run:

    @powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('http://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%systemdrive%\chocolatey\bin

Then start a new powershell, cygwin or mingw32 shell. You can now install the
Ruby framework:

    cinst ruby.devkit

Now, restart your shell or reload its path variable. You now have rake
installed. Now you can install Albacore, the collection of tasktypes, tasks and
extension points aimed to make your life as a .Net developer easier:

    gem install bundler

Bundler is a tool that fetches gems for you. Now, specify what ruby gems your
build will use. Create a new file, named `Gemfile`. This file should look like
this:

    source 'http://rubygems.org'
    gem "albacore", :git => "git://github.com/Albacore/albacore.git", :branch => 'clean_slate'

Now, install albacore from this repository by running:

    bundle

In order to build your project, you need to create a `Rakefile`, with contents
like these:

    require 'bundler/setup'
    require 'albacore'

    build :build do |x|
      x.sln = 'src/MyProj.sln'
    end
 
You can now run:

    rake

## Links

 * http://guides.rubygems.org/make-your-own-gem/
 * http://postmodern.github.com/2012/05/22/rubygems-tasks.html
 * https://github.com/guard/guard-rspec
 * http://barkingiguana.com/2011/12/13/how-i-structure-rubygems/
 * http://rakeroutes.com/blog/lets-write-a-gem-part-one/
 * https://github.com/sj26/ruby-1.9.3-p0/blob/master/lib/rake/application.rb
 * https://github.com/sj26/ruby-1.9.3-p0/blob/master/lib/rake/rake_module.rb
