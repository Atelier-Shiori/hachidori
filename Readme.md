[![Build Status](https://travis-ci.org/chikorita157/hachidori.svg?branch=master)](https://travis-ci.org/chikorita157/hachidori)
# Hachidori
Hachidori (はちどり) is an open sourced Hummingbird.me client for OS X based on the same codebase as MAL Updater OS X, but designed exclusively for Hummingbird.

Warning: Still a work in progress since this is an Alpha. 
 
Requires latest SDK (10.10) and XCode 6.1 to compile. Deployment target is 10.8.

## How to use
See [Getting Started Guide](https://github.com/chikorita157/hachidori/wiki/Getting-Started).

## How to Compile in XCode
1. Get the Source
2. Type 'xcodebuild' to build

## Running Unit Tests
To run unit test, open the XCode Project and then press Cmd + T or type the following in the terminal 

``xcodebuild -scheme Hachidori test``

This will test how Hachidori finds the associated ID for a detected title with a set dataset. Dataset is found under the unit test directory as a file named "testdata.json".

## Dependencies
All the frameworks are included. Just build! Here are the frameworks that are used in this app:

* anitomy-osx.framework (Framework version and adapted version of anitomy C++ library. Source code is in Framework folder.)
* Sparkle.framework
* OgreKit.framework
 
Licenses for these frameworks and related classes can be seen [here](https://github.com/chikorita157/hachidori/wiki/Credits).

##License
Unless stated, Source code is licensed under New BSD License
 
Copyright © 2009-2014, Atelier Shiori.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 

3. Neither the name of the Atelier Shiori nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.


THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.