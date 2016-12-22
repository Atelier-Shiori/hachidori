# Hachidori
Hachidori (はちどり) is an open sourced kitsu.io client for OS X based on the same codebase as MAL Updater OS X, but designed exclusively for Kitsu formerly known as Hummingbird.
 
Requires latest SDK (10.12) and XCode 8 or later to compile. Deployment target is 10.9.

Help the development of Hachidori by becoming our [Patreon](http://www.patreon.com/chikorita157)

## How to use
See [Getting Started Guide](https://github.com/Atelier-Shiori/wiki/Getting-Started).

## How to Compile in XCode
Warning: This won't work if you don't have a Developer ID installed. If you don't have one, obtain one by joining the Apple Developer Program or turn off code signing.

1. Get the Source
2. Type 'xcodebuild' to build

## Running Unit Tests
To run unit test, open the XCode Project and then press Cmd + T or type the following in the terminal 

``xcodebuild -scheme Hachidori test``

This will test how Hachidori finds the associated ID for a detected title with a set dataset and calculate the accuracy. Dataset is found under the unit test directory as a file named "testdata.json".

## Help Localize Hachidori

Hachidori is now a localizable application. If you want to help translate, create a fork, add localization to localizable.strings and commit the translated localiable strings file only. Localizable.string file is located in the [Base.lproj](https://github.com/Atelier-Shiori/hachidori/tree/master/Base.lproj) folder.

## Dependencies
All the frameworks are included. Just build! Here are the frameworks that are used in this app:

* anitomy-osx.framework (Included as a submodule)
* Sparkle.framework
* OgreKit.framework
* OAuth2Client.framework
 
Licenses for these frameworks and related classes can be seen [here](https://github.com/Atelier-Shiori/wiki/Credits).

##License
Unless stated, Source code is licensed under [New BSD License](https://github.com/Atelier-Shiori/hachidori/blob/master/License.md).
