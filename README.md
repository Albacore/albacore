# Albacore Clean Slate

[![Build Status](https://secure.travis-ci.org/Albacore/albacore.png?branch=clean_slate)](http://travis-ci.org/Albacore/albacore)

This branch is the next official version. It is currently being used for
numerous builds for us and is free of known bugs. It works on RMI 1.9.3 and
jRuby.

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
    require 'albacore/tasks/versionizer'
    require 'albacore/ext/teamcity'

    Albacore::Tasks::Versionizer.new :versioning

    desc "Perform fast build (warn: doesn't d/l deps)"
    build :quick_build do |b|
      b.logging = 'detailed'
      b.sln = 'src/MyProj.sln'
    end

    desc "Perform full build"
    build :build => [:versioning, :restore] do |b|
      b.sln = 'src/MyProj.sln'
    end

    directory 'build/pkg'

    nugets_restore :restore do |p|
      p.out = 'src/packages'
      p.exe = 'buildsupport/NuGet.exe'
    end

    desc "package nugets"
    nugets_pack :create_nugets => ['build/pkg', :versioning, :build] do |p|
      p.files   = FileList['src/**/*.{csproj,fsproj,nuspec}'].
        exclude('src/Fsharp.Actor/*.nuspec').
        exclude(/Tests/).
        exclude(/Spec/).
        exclude(/sample/).
        exclude(/packages/)
      p.out     = 'build/pkg'
      p.exe     = 'buildsupport/NuGet.exe'
      p.version = ENV['NUGET_VERSION']
    end
 
You can now run:

    rake

## hack guidelines

Use pair-of-three: `Cmd`, `Config` and `Task`. Add Rakefile-methods in `dsl.rb`.
You can `include CmdConfig` in your `Config` to get access to parameters, and do
`include CrossPlatformCmd` in your `Cmd` to get correct cross-platform, logging
and invocation of system and shell statements.

Read the READMEs in the `lib/ext` and `lib/tasks` folders. Write unit-tests for
your functionality. Try to make the execution of the command that you have
prepared be a single line of code that does something like: `sh make_command`
thereby delegating to `CrossPlatformCmd`. To ignore exit codes, call `shie`
instead.

Use and document `attr_accessor` in `Config` with [TomDoc](http://tomdoc.org/),
so that docs can be automatically generated. Have sane defaults. If an option is
true/false, have a sane default and provide a method that sets the opposite.
Document the default. Document required properties to set. Don't set properties
by providing single-parameter methods, because it's confusing with regards to
reading those same properties.

'Execute' the configuration as much as possible when configuring it through the
DSL block, but don't do side-effects other than fail bad config. Remember that
multiple interactions with the `Config` object is desired. Do side-effects when
the task is run.

How to write commands:

    require 'map'

    # ...

    def initialize executable, *args
      opts = Map.options(args)
      @executable = executable  
    end

In general: look at the written code and do something similar =).

Provide further blocks/lambdas/procs, passed from the `Config` to the `Task` or
even `Cmd` if you need to decide values when the task is run. This makes it
easier to compose tasks.

I use a vague concept of 'core albacore' for tasktypes (nugets_restore,
nugets_pack, build) and 'extensions' for things that depend on published
symbols, and 'tasks' for things that can be instantiated (added to the Rake
Tasks collection) in the Rakefile. Your extension probably is a 'task' or
'extension'.

Use ideomatic ruby. If you have more than 3 levels of indentation in a method,
you're probably not being ideomatic. Can you use a higher-level language
construct or the null-object pattern or some functional programming concept that
makes the code easier to read, reason about and maintain? Don't mutate unless
you have to - code that doesn't mutate much can be gotten by using the builder
pattern (`Config` is the builder most of the time); then, a lot of the logic of
how to construct the command-line/expression to run, can be done in the
constructor (`Cmd#initialize`), rather than when executing it.

### Usage of csprojfiles

    desc "Check the difference between the filesystem and the files referenced in a csproj"
	csprojfiles do |f|
		# Files to ignore
		# for instance if you have source control specific files that are not supposed to be in the project 
    	f.ignore_files = [/.*\.srccontrol/] 
    	f.project = "src/MyMvcSite/MyMvcSite.csproj"
  	end

When you run this task it will report any differences between the filesystem and the csproj file.

Why is this important? It's important to know what resources will be deployed. For instance if you have added an image. If you forgot to include the image in the .csproj, it will show up while developing but not when you do a web deployment (i.e. a release).

It could also be that you have deleted a file, but forgotten to save the project when you send your latest commit to source control&hellip;

How do you use it? The best way is to have it on a CI server in order to get a notification whenever it detects deviations.

The task will fail with a message and rake will return with an non zero exit code. For instance if a file is missing from csproj and another from the filesystem:

    - Files in src/MyMvcSite/MyMvcSite.csproj but not on filesystem: 
    file_missing_on_filesystem.cshtml
    + Files not in src/MyMvcSite/MyMvcSite.csproj but on filesystem:
    file_missing_in_csproj.png

## Links

 * http://guides.rubygems.org/make-your-own-gem/
 * http://postmodern.github.com/2012/05/22/rubygems-tasks.html
 * https://github.com/guard/guard-rspec
 * http://barkingiguana.com/2011/12/13/how-i-structure-rubygems/
 * http://rakeroutes.com/blog/lets-write-a-gem-part-one/
 * https://github.com/sj26/ruby-1.9.3-p0/blob/master/lib/rake/application.rb
 * https://github.com/sj26/ruby-1.9.3-p0/blob/master/lib/rake/rake_module.rb
