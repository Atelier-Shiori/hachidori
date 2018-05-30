//
//  PlexAuth.h
//  DetectionKit
//
//  Created by 天々座理世 on 2017/07/07.
//  Copyright © 2017年 Atelier Shiori. All rights reserved.  Code licensed under New BSD License
//

#import <Foundation/Foundation.h>
/**
 This class handles Plex Media Server authentication.
 */
@interface PlexAuth : NSObject
/**
 Authenticates a Plex account with a given username and password. If authentication is successful, the token is saved to the login keychain.
 @pram username The plex account's username.
 @pram password The password for the provided account.
 @param completionHandler The completion handler containing the success status
 */
+ (void)performplexlogin:(NSString *)username withPassword:(NSString *)password completion:(void (^)(bool success)) completionHandler;
/**
 Removes a plex account
 @return bool If account removal is successful.
 **/
+ (bool)removeplexaccount;
/**
 Checks if a plex account exists in the Keychain. If so, return the username. If not, it will return a blank string.
 @return NSString The username of the first account it found.
 **/
+ (NSString *)checkplexaccount;
@end
