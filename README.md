# Albacore Clean Slate

[![Build Status](https://secure.travis-ci.org/Albacore/albacore.png?branch=clean_slate)](http://travis-ci.org/Albacore/albacore)

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

Give your `Cmd` objects this signature:

    def initialize work_dir, executable, *args

Provide further blocks/lambdas/procs, passed from the `Config` to the `Task` or
even `Cmd` if you need to decide values when the task is run. This makes it
easier to compose tasks.

I use a vague concept of 'core albacore' for tasktypes (nugets_restore,
nugets_pack, build) and 'extensions' for things that depend on published
symbols, and 'tasks' for things that can be instantiated (added to the Rake
Tasks collection) in the Rakefile. Your extension probably is a 'task' or
'extension'.

When using `Cmd` and its `@parameters`; unless you use `#make_command`, remember
to normalize slashes (e.g. Paths#normalize_slashes).

Provide a very basic example in TomDoc on top of your `Config` class.

Use ideomatic ruby. If you have more than 3 levels of indentation in a method,
you're probably not being ideomatic. Can you use a higher-level language
construct or the null-object pattern or some functional programming concept that
makes the code easier to read, reason about and maintain? Don't mutate unless
you have to - code that doesn't mutate much can be gotten by using the builder
pattern (`Config` is the builder most of the time); then, a lot of the logic of
how to construct the command-line/expression to run, can be done in the
constructor (`Cmd#initialize`), rather than when executing it.

## Links

 * http://guides.rubygems.org/make-your-own-gem/
 * http://postmodern.github.com/2012/05/22/rubygems-tasks.html
 * https://github.com/guard/guard-rspec
 * http://barkingiguana.com/2011/12/13/how-i-structure-rubygems/
 * http://rakeroutes.com/blog/lets-write-a-gem-part-one/
 * https://github.com/sj26/ruby-1.9.3-p0/blob/master/lib/rake/application.rb
 * https://github.com/sj26/ruby-1.9.3-p0/blob/master/lib/rake/rake_module.rb
