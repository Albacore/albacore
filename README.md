# Albacore [![Build Status](https://secure.travis-ci.org/Albacore/albacore.png?branch=dev)](http://travis-ci.org/Albacore/albacore)

Albacore is a suite of Rake tasks for building .NET systems. It's like MSBuild or NAnt... but without all the stabby-bracket XML hell!

## Getting Started

Check out the [Wiki](https://github.com/Albacore/albacore/wiki) for detailed instructions on how to use the built in tasks. If you are new to Ruby or Rake, head over to the [getting started](https://github.com/Albacore/albacore/wiki/Getting-Started) wiki page.

## Supported Rubies

Albacore has been tested against the following versions of Ruby for Windows and Linux:

* MRI v1.8.7
* MRI v1.9.2
* MRI v1.9.3
* JRuby v1.6.7
* IronRuby v1.0
* IronRuby v1.1
* IronRuby v1.1.1
* IronRuby v1.1.2
* IronRuby v1.1.3


### Unsupported Rubies

Support for the following versions of ruby has been dropped. Albacore will no longer be tested against, or have code written to work with these versions of ruby. Use these versions at your own risk.

* MRI v1.8.6
* MRI v1.9.1

### Notes on IronRuby

Due to an incompatibility with the Rubyzip gem, IronRuby does not support the ‘zip’ and ‘unzip’ tasks. If you need zip / unzip support, look into using a third party tool such as [7-zip](http://7-zip.org) or [SharpZipLib](http://sharpdevelop.net/OpenSource/SharpZipLib/).

### Notes on Linux/Mono and JRuby

Albacore is moving forward. Part of this is making sure it works on alternative operating systems. 

 * 2012-08-26 First few rspec categories running on travis with 1.8.7, 1.9.2, 1.9.3 and jruby.
