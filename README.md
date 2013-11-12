# Albacore Clean Slate

[![Build Status](https://secure.travis-ci.org/Albacore/albacore.png?branch=clean_slate)](http://travis-ci.org/Albacore/albacore)

Version 2.0 of Albacore.

This branch is the next official version. It is currently being used for
numerous builds for us and is free of known bugs. It works on RMI 1.9.3.

    gem install albacore --prerelease

## Getting Started

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
    gem 'albacore', '2.0.0.rc.2'

Now, install albacore from this repository by running:

    bundle

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
  p.exe = 'buildsupport/NuGet.exe'
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
end

task :default => :create_nugets
```

You can now run:

    rake

## Contributing

 1. Create a feature branch with your change:
    a. With unit test
    b. With feature
 1. Send a PR with that feature branch to this branch
    a. Make sure TravisCI is OK with it
    b. Describe your PR in English.

## Task Types

Task types are the pre-built factories for rake tasks. They often take care of
what's slightly more complex, beyond just invoking commands.

### Docs: build

TBD

### Docs: nugets_pack

TBD

### Docs: nugets_restore

TBD

### Docs: asmver

Generate a single file with assembly attributes. Code comments in example below
mention output in F#.

``` ruby
asmver :asmver do |a|
  a.file_path  = 'src/Version.fs' # required, no default
  a.namespace  = 'Hello.World'    # required for F#, defaults to empty string '' for C#
  # optional
  a.attributes assembly_title: 'Hello.World', # generates: [<AssemblyTitle("Hello.World")>]
    assembly_version: '0.1.2',                # generates: [<AssemblyVersion("0.1.2")>]
    my_product_attr: 'Hello world',           # generates: [<MyProductAttr("Hello World")>]
  a.out        = StringIO.new     # optional, don't use it this way: takes an IO/Stream
end
```

### Docs: test_runner

TBD

### Docs: nugets_authentication

TBD

## Tasks

Tasks are things you can include that create singleton ruby tasks that are
pre-named and pre-made. As opposed to the task types, these are 'includeable'.
More info can be found in the
[README](https://github.com/Albacore/albacore/blob/clean_slate/lib/albacore/tasks/README.md).

### Versionizer

Helper for reading a `.semver` file and moving information from that file, as
well as information from the git commit being built upon, to the execution of
rake/albacore.

Defines/sets ENV vars:

 * BUILD_VERSION
 * NUGET_VERSION
 * FORMAL_VERSION

BUILD_VERSION s constructed as such: `.semver-file -> %Major.%minor.%patch%special.git-sha1`.

NUGET_VERSION leaves out the git commit hash.

FORMAL_VERSION uses only the integers 'major', 'minor' and 'patch'.

Publishes symbol `:build_version`.

``` ruby
Albacore::Tasks::Versionizer.new :versioning
```

## Tools

Tools are auxilliary items in albacore. They do not have the same amount of
testing and are more often one-off utilities. Most of these should be moved to
being commands in an albacore binary.

### Docs: csprojfiles

Checks the difference between the filesystem and the files referenced in a
csproj, to make sure that they match. Run as a part of a CI build.

``` ruby
desc "Check the difference between the filesystem and the files referenced in a csproj"
csprojfiles do |f|
  # Files to ignore
  # for instance if you have source control specific files that are not supposed to be in the project 
  f.ignore_files = [/.*\.srccontrol/]
  f.project = "src/MyMvcSite/MyMvcSite.csproj"
end
```

When you run this task it will report any differences between the filesystem and
the csproj file.

Why is this important? It's important to know what resources will be deployed.
For instance if you have added an image. If you forgot to include the image in
the .csproj, it will show up while developing but not when you do a web
deployment (i.e. a release).

It could also be that you have deleted a file, but forgotten to save the project
when you send your latest commit to source control&hellip;

How do you use it? The best way is to have it on a CI server in order to get a
notification whenever it detects deviations.

The task will fail with a message and rake will return with an non zero exit
code. For instance if a file is missing from csproj and another from the
filesystem:

    - Files in src/MyMvcSite/MyMvcSite.csproj but not on filesystem: 
      file_missing_on_filesystem.cshtml
    + Files not in src/MyMvcSite/MyMvcSite.csproj but on filesystem:
      file_missing_in_csproj.png

## Ideas:

When building multiple configurations,
Build tasks should be invoked with different parameters
According to the graph of tasks to be executed

``` ruby
require 'albacore'

Albacore.vary_by_parameters do |params|
  # write to dynamic method
  params.Configuration = ['Debug-Tests', 'Release']
end

build :b do |b|
  b.vary_by_param 'Configuration'
end

nugets_pack :p => :b do |p|
 # ... 
end

task :default => :p
```

Creating two runs
  * `:b[Debug-Tests] => :p => :default` and
  * `:b[Release] => :p => :default`

where only :b is invoked twice, but :p and :default are only invoked only once
each.

---

When building services and/or web sites,
The bundling task_type should take care of packaging for deployment

