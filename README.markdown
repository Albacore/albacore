# Welcome to the Albacore Project [![Build Status](https://secure.travis-ci.org/Albacore/albacore.png?branch=dev)](http://travis-ci.org/Albacore/albacore)

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

## Contributing

You are very welcome to submit pull requests - preferrably to the *dev* branch, which is merged with master at release-time. You will be notified by Travis, our servant, whether your pull request passes all tests (and your *newly written* tests, too), in your pull request discussion area.

When the code has been vetted and merged, it will be included in the next gem build.

## MIT License

Copyright (c) 2011 Derick Bailey, Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
