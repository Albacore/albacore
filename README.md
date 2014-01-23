# Albacore

[![Build Status](https://secure.travis-ci.org/Albacore/albacore.png?branch=clean_slate)](http://travis-ci.org/Albacore/albacore)

Version 2.0 of Albacore.

This branch is the next official version. It is currently being used for
numerous builds for us and is free of known bugs. It works on RMI 1.9.3 and RMI
2.0.

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
    gem 'albacore', '2.0.0.rc.5'

When setting up your build you need to ensure it is reproducible.  Bundler
allows you to lock down all gems that albacore depend on to their specific
versions, ensuring that your peers can re-run the same rake script you just
built and that it works well on your continous integration server.

The first step after installing `bundler` is to create a `Gemfile` next to your
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

## DSL

When you `require 'albacore'` you will get a few methods added and available for
use within your Rakefile, these are specified in CrossPlatformCmd, and are as
follows:

 - `#system`
 - `#sh`
 - `#shie`
 - `#system_control`
 - `#which`
 - `#normalise_slashes` 
 - `#chdir (work_dir : ?string) (block : Block<unit, x>) : x` - takes a string work dir to be
   in and a block of ruby to execute in that work dir and returns the return
   value of block.


## Debugging Albacore scripts

You can call the rakefile as such:

```
DEBUG=true rake
```

This changes the behaviour of the logging to output debug verbosity. It also
changes some tasks to override Rakefile settings for verbosity and prints more
debug information. I've tried to keep the information structured.

If you're reporting a bug or need crash information to file a bug report, you
can append the `--trace` flag to the invocation.

```
DEBUG=true rake --trace
```

## Task Types

Task types are the pre-built factories for rake tasks. They often take care of
what's slightly more complex, beyond just invoking commands. They are available
and methods in the DSL you get when you do `require 'albacore'`

### Docs: build

``` ruby
require 'albacore'
build :compile_this do |b|
  b.file   = Paths.join 'src', 'MyProj.fsproj' # the file that you want to build
  # b.sln  = Paths.join 'src', 'MyProj.sln'    # alt. name
  b.target = ['Clean', 'Rebuild']              # call with an array of targets or just a single target
  b.prop 'Configuration', 'Release'            # call with 'key, value', to specify a MsBuild property
  b.cores = 4                                  # no of cores to build with, defaults to the number of cores on your machine
  b.clp 'ShowEventId'                          # any parameters you want to pass to the console logger of MsBuild
  b.logging 'verbose'                          # verbose logging mode
  # b.be_quiet                                 # opposite of the above
  b.no_logo                                    # no Microsoft/XBuild header output
end

```

### Docs: nugets_pack

TBD

#### #no_project_dependencies

Cancel following of references between projects that cause nugets_pack to find and add as nuget dependencies, linked projects.

```
# TODO
```

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

