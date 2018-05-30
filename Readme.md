# Hachidori
Hachidori (はちどり) is an open sourced [Kitsu](https://kitsu.io) and [AniList](https://anilist.co) scrobbler for macOS.
 
Requires latest SDK (10.13) and XCode 9 or later to compile. Deployment target is 10.11.

## Supporting this Project

Like this program and want to support the development of this program? You can [Donate](https://malupdaterosx.moe/donate/) $5 and you will recieve a donation key to remove the reminder message at startup every two weeks and enable additional features like the Bittorrent browser.

## How to use
See [Getting Started Guide](https://github.com/Atelier-Shiori/wiki/Getting-Started).

## How to Compile in XCode
Warning: This won't work if you don't have a Developer ID installed. If you don't have one, obtain one by joining the Apple Developer Program or turn off code signing.

1. Get the Source
2. Type 'xcodebuild' to build

If you are going to distribute your own version and change the name, please change the bundle identifier to something else.


## Dependencies
All the frameworks are included. Just build! Here are the frameworks that are used in this app:

* anitomy-osx.framework (Included as a submodule)
* AFNetworking.framework
* DetectionKit.framework
* GBPing.framework
* PingNotifier.framework
* EasyNSURLConnection.framework
* MASPreferences.framework
* MASShortcut.framework
* Sparkle.framework
* CocoaOniguruma.framework
* streamlinkdetect.framework
* Reachability.framework
* DetectionKit.framework
 
Licenses for these frameworks and related classes can be seen [here](https://github.com/Atelier-Shiori/wiki/Credits).

## License

Unless stated, Source code is licensed under [New BSD License](https://github.com/Atelier-Shiori/hachidori/blob/master/License.md).
