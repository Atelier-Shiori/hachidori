# Hachidori
Hachidori (はちどり) is an open sourced [Kitsu](https://kitsu.io), [AniList](https://anilist.co), and [MyAnimeList](https://myanimelist.net) scrobbler for macOS. Hachidori is the successor for MAL Updater OS X.
 
Requires latest SDK (10.15) and XCode 11 or later to compile. Deployment target is 10.11.

Note: This is the prerelease branch, which contains MyAnimeList support. You won't be able to compile without an MyAnimeList OAuth client key, which is not obtainable until the API is out of beta.

## Supporting this Project

Like this program and want to support the development of this program? You can [Donate](https://malupdaterosx.moe/donate/) $5  and you will recieve a donation key to remove the reminder message at startup every two weeks and enable additional features like the Bittorrent browser. You may also choose to support us on [Patreon](https://www.patreon.com/malupdaterosx) as well.

## How to use
See [Getting Started Guide](https://github.com/Atelier-Shiori/wiki/Getting-Started).

## How to Compile in XCode
Warning: This won't work if you don't have a Developer ID installed. If you don't have one, obtain one by joining the Apple Developer Program or turn off code signing.

Notary support will come after macOS Mojave final release.

1. Get the Source
2. Type 'xcodebuild' to build

If you are going to distribute your own version and change the name, please change the bundle identifier to something else.


## Dependencies
All the frameworks are included. Just build! Here are the frameworks that are used in this app (excluding related projects):

* AFNetworking.framework
* GBPing.framework
* PingNotifier.framework
* MASPreferences.framework
* MASShortcut.framework
* Sparkle.framework
* CocoaOniguruma.framework
* Reachability.framework
* DetectionKit.framework
 
Licenses for these frameworks and related classes can be seen [here](https://github.com/Atelier-Shiori/wiki/Credits).

## Related Projects
Hachidori depends on these frameworks and services, which provides core functionality.
* [DetectionKit](https://github.com/Atelier-Shiori/DetectionKit) - Cocoa Framework responsible for all media detection.
* [detectstream](https://github.com/Atelier-Shiori/detectstream) - A Cocoa Framework that detects legal streaming sites from web browser. Provides parsing for streamlink as well, which is handled by DetectionKit.
* [anitomy-for-cocoa](https://github.com/Atelier-Shiori/anitomy-for-cocoa) - Anitomy wrapper for Objective-C to parse video file names.
* [Hato](https://github.com/Atelier-Shiori/Hato) - Web API that makes looking up Title Identifiers for Anime and Manga on other Media Discovery services easy.

## License

Unless stated, Source code is licensed under [New BSD License](https://github.com/Atelier-Shiori/hachidori/blob/master/License.md).
