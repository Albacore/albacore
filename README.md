# Albacore [![Build Status](https://secure.travis-ci.org/Albacore/albacore.png?branch=dev)](http://travis-ci.org/Albacore/albacore) [![Gem Version](https://badge.fury.io/rb/albacore.png)](http://badge.fury.io/rb/albacore) [![Dependency Status](https://gemnasium.com/Albacore/albacore.png)](https://gemnasium.com/Albacore/albacore) [![Code Climate](https://codeclimate.com/github/Albacore/albacore.png)](https://codeclimate.com/github/Albacore/albacore) [![Coverage Status](https://coveralls.io/repos/Albacore/albacore/badge.png)](https://coveralls.io/r/Albacore/albacore)

Albacore is a suite of Rake tasks for building .NET systems. It's like MSBuild or NAnt... but without all the stabby-bracket XML hell! Browse the [detailed instructions][1] for each task, or, if you're new to Ruby/Rake, review [the quickstart][2].

## Installation

Add these lines to the Gemfile where you maintain the dependencies for your build:

    gem 'rake'
    gem 'albacore'

And then execute

    $ bundle
    
Or install them yourself:

    $ gem install rake
    $ gem install albacore

## Usage

Require the Albacore gem at the top of your rakefile:

    require 'albacore'

Consult the [quickstart][1] or the detailed [task instructions][2] for more information on how to use Albacore tasks in your Rake build.

## Supported Rubies

Albacore has been tested against the following versions of Ruby for Windows and Linux. Use unsupported versions at your own risk!

* MRI [ '1.8.7', '1.9.2', '1.9.3' ]
* JRuby [ '1.6.7' ]
* IronRuby [ '1.0', '1.1', '1.1.1', '1.1.2', '1.1.3' ]

Due to an incompatibility with the Rubyzip gem, IronRuby does not support the ‘zip’ and ‘unzip’ tasks. If you need support, use a third party tool like [7-zip](http://7-zip.org) or [SharpZipLib](http://sharpdevelop.net/OpenSource/SharpZipLib/).

Albacore is moving forward to support alternative operating systems. 

 * 2012-08-26 First few rspec categories running on travis with 1.8.7, 1.9.2, 1.9.3 and jruby.


 [1]: https://github.com/Albacore/albacore/wiki
 [2]: https://github.com/Albacore/albacore/wiki/Getting-Started
