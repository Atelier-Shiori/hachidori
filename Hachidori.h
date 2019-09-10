//
//  Hachidori.h
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2018 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>
#import <AFNetworking/AFOAuth2Manager.h>
#import "AniListConstants.h"
#import "DiscordManager.h"
#import "DetectedScrobbleStatus.h"
#import "LastScrobbleStatus.h"
#import "HachidoriTwitterManager.h"
#import "AniListUpdateManager.h"
#import "KitsuUpdateManager.h"

@class Reachability;
@class Detection;
@class AFHTTPSessionManager;
@class HachidoriTwitterManager;

@interface Hachidori : NSObject
typedef NS_ENUM(unsigned int, ScrobbleStatus) {
    ScrobblerNothingPlaying = 0,
    ScrobblerSameEpisodePlaying = 1,
    ScrobblerUpdateNotNeeded = 2,
    ScrobblerConfirmNeeded = 3,
    ScrobblerDetectedMedia = 4,
    ScrobblerAddTitleSuccessful = 21,
    ScrobblerUpdateSuccessful = 22,
    ScrobblerOfflineQueued = 23,
    ScrobblerTitleNotFound = 51,
    ScrobblerAddTitleFailed = 52,
    ScrobblerUpdateFailed = 53,
    ScrobblerFailed = 54,
    ScrobblerInvalidScrobble = 58
};
typedef NS_ENUM(unsigned int, ratingType) {
    ratingSimple = 0,
    ratingStandard = 1,
    ratingAdvanced = 2
};
typedef NS_ENUM(unsigned int, anilistRatingType) {
    ratingPoint100 = 0,
    ratingPoint10Decimal = 1,
    ratingPoint10 = 2,
    ratingPoint5 = 3,
    ratingPoint3 = 4
};
typedef NS_ENUM(unsigned int, hachidoriservice) {
    serviceKitsu = 0,
    serviceAniList = 1
};
@property (strong) AFHTTPSessionManager *syncmanager;
@property (strong) AFHTTPSessionManager *asyncmanager;
@property (strong) NSString *username;
@property (strong) NSString *malusername;
@property BOOL _online;
@property BOOL testing;
@property (getter=getSuccess) BOOL Success;
@property (strong) NSString *MALID;
@property (strong) NSString *MALApiUrl;
@property BOOL correcting;
@property BOOL unittesting;
@property (strong) Reachability* reach;
@property (strong, setter=setManagedObjectContext:) NSManagedObjectContext *managedObjectContext;
@property (getter=getOnlineStatus) bool online;
@property (getter=getRatingType) int ratingtype;
@property (strong) Detection *detection;
@property (strong) HachidoriTwitterManager *twittermanager;
@property (strong) DiscordManager *discordmanager;
@property (strong) AniListUpdateManager *anilistmanager;
@property (strong) KitsuUpdateManager *kitsumanager;

- (void)setManagedObjectContext:(NSManagedObjectContext *)context;
- (int)getQueueCount;
+ (long)currentService;
+ (NSString *)currentServiceName;
+ (NSString *)serviceNameWithServiceID:(int)service;
+ (AFOAuthCredential *)getCurrentFirstAccount;
+ (AFOAuthCredential *)getFirstAccount:(long)service;
+ (NSString *)getUserid:(int)service;
- (int)startscrobbling;
- (NSDictionary *)scrobblefromqueue;
- (int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)onetime;
- (int)scrobble;
- (BOOL)confirmupdate;
- (NSDictionary *)checkexpired;
- (void)refreshtokenwithdictionary:(NSDictionary *)servicedict successHandler:(void (^)(bool success, int numfailed)) successHandler;
- (void)refreshtokenWithService:(int)service successHandler:(void (^)(bool success)) successHandler;
- (void)retrieveUserID:(void (^)(int userid, NSString *username, NSString *scoreformat)) completionHandler error:(void (^)(NSError * error)) errorHandler withService:(int)service;
- (void)resetinfo;
- (int)getUserRatingType;
- (void)setNotifier;
- (void)sendDiscordPresence:(LastScrobbleStatus *)lscrobble;
// Unit Testing Only
- (NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season group:(NSString *)group type:(NSString *)type;

// Scrobble Status
- (DetectedScrobbleStatus *)getDetectedScrobbleForService:(int)service;
- (void)setDetectedScrobbleStatus:(DetectedScrobbleStatus *)dscrobble withService:(int)service;
- (LastScrobbleStatus *)getLastScrobbleForService:(int)service;
- (void)setLastScrobbleStatus:(LastScrobbleStatus *)lscrobble withService:(int)service;
- (void)resetDetected;
- (LastScrobbleStatus *)lastscrobble;
- (DetectedScrobbleStatus *)detectedscrobble;
@end
