//
//  Detection.h
//  DetectionKit
//
//  Created by Tail Red on 1/31/15.
//  Copyright 2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Foundation/Foundation.h>

@class OnigRegexp;
@class OnigResult;
/**
 This class allows you to detect media that is playing
 */
@interface Detection : NSObject
/**
 The current Kodi Json RPC reachability status.
 */
@property (getter=getKodiOnlineStatus) bool kodionline;
/**
 The current Kodi Json RPC reachability status.
 */
@property (getter=getPlexOnlineStatus) bool plexonline;

/**
 This detects media from open video players, streams or web browsers
 @return NSDictionary The detected information of a media file or stream.
 */
- (NSDictionary *)detectmedia;
/**
 Checks if the stream link title is on a ignore list.
 @param d Stream information of a streamlink stream.
 @return NSArray The detected information of a stream.
 */
- (NSDictionary *)checksstreamlinkinfo:(NSDictionary *)d;
/**
 Turns on/off Kodi JSON RPC reachability.
 @pram enable The state of the Kodi JSON RPC reachability.
 */
- (void)setKodiReach:(BOOL)enable;
/**
 Sets the address for the Kodi reachability
 @pram url The host name to the computer running Kodi.
 */
- (void)setKodiReachAddress:(NSString *)url;
/**
 Turns on/off Plex Media Server API reachability.
 @pram enable The state of the Plex API reachability.
 */
- (void)setPlexReach:(BOOL)enable;
/**
 Sets the address for the Plex Media Server reachability
 @pram url The host name/IP Address to the computer running Plex Media Server.
 */
- (void)setPlexReachAddress:(NSString *)url;
@end
