# Contributing

You can contribute to the Albacore framework in many ways.

* Submit or comment on [issues][1] (add your vote to an issue by leaving a "+1" comment).
* Post questions or comment on discussions about development and usage on the [user group][2].
* Submit code changes via pull requests or comment on code reviews (details below).

## Overview

Start by [forking the repository][3]. Make your changes in the *dev* branch (or a feature branch, whichever you're most comfortable with). Make sure to add or edit tests, as necessary. Submit your pull request to the Albacore/albacore *dev* branch. You will be notified by Travis, our servant, whether your pull request passes all tests. When the code has been reviewed and merged, it will be included in the next gem.

Be sure to set your [line-endings][4] correctly for your platform, *before* you start developing.

## Building the Albacore Package

tl;dr

``` bash
$ git clone git://github.com/Albacore/albacore.git -b dev
$ gem install bundler
$ bundle
$ rake install
```

The full instructions for building the Albacore package should be similar to other Github and Ruby gem projects. Fork or clone the Albacore/albacore repository and immediately use the *dev* branch.

``` bash
$ git clone git://github.com/Albacore/albacore.git -b dev
```

You need the Bundler gem to install all of the Albacore development and runtime dependencies.

``` bash
$ gem install bundler
```

If you are developing on the Windows platform, you will also need the [RubyInstaller Development Kit][8] (DevKit). There are complicated [manual install instructions][9], but we recommend using the [DevKit package][10] from Chocolatey. Then, you can ask Bundler to install the dependencies listed in the `Gemfile` and `albacore.gemspec`.

``` bash
$ bundle install
```

You can build the Albacore `.gem` package using the built-in rake task.

``` bash
$ rake build
```

And you may install that same gem on your local system

``` bash
$ gem install --local path/to/albacore.x.y.z.gem
```

Or, you can build & install in one step

``` bash
$ rake install
```

## Running Tests with RSpec

You can get a list of the available spec categories by running `rake -T`, they start with `specs:`. The `specs:all` task will run *all* of the specs. You can colorize the spec run output on your console with RSpec `~>2.7` and [ansicon][5]. We recommend installing the [ansicon package][6] using the [Chocolatey][7] package manager.

``` bash
$ rake specs:all
```

The NCover and NDepend specs categories require a valid license to be installed on your system or they will fail. You can ignore those failures or run the special specs category `specs:except_ncover`.


 [1]: http://github.com/Albacore/albacore/issues 
 [2]: http://groups.google.com/group/albacoredev
 [3]: http://help.github.com/forking/
 [4]: http://help.github.com/dealing-with-lineendings/
 [5]: http://adoxa.3eeweb.com/ansicon/ 
 [6]: http://chocolatey.org/packages/ansicon
 [7]: http://chocolatey.org/
 [8]: http://rubyinstaller.org/add-ons/devkit/
 [9]: https://github.com/oneclick/rubyinstaller/wiki/Development-Kit
 [10]: http://chocolatey.org/packages/ruby.devkit
