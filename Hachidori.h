//
//  Hachidori.h
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2018 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>
#import <AFNetworking/AFOAuth2Manager.h>
#import "AniListConstants.h"
#import "DiscordManager.h"

@class Reachability;
@class Detection;
@class AFHTTPSessionManager;
@class TwitterManager;

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
    ScrobblerFailed = 54
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
@property (strong) AFHTTPSessionManager *syncmanager;
@property (strong) AFHTTPSessionManager *asyncmanager;
@property (strong) AFHTTPSessionManager *malcredmanager;
@property (strong) AFHTTPSessionManager *malmanager;
@property (strong, getter=getLastScrobbledTitle) NSString *LastScrobbledTitle;
@property (strong, getter=getLastScrobbledEpisode) NSString *LastScrobbledEpisode;
@property (strong, getter=getLastScrobbledActualTitle) NSString *LastScrobbledActualTitle;
@property (strong, getter=getLastScrobbledSource) NSString *LastScrobbledSource;
@property (strong) NSString *username;
@property (strong) NSString *malusername;
@property (strong, getter=getLastScrobbledInfo) NSDictionary *LastScrobbledInfo;
@property (getter=getisNewTitle) BOOL LastScrobbledTitleNew;
@property (getter=getPrivate) BOOL isPrivate;
@property BOOL _online;
@property BOOL testing;
@property (strong) NSString *DetectedTitle;
@property (strong) NSString *DetectedEpisode;
@property (strong) NSString *DetectedSource;
@property (strong) NSString *DetectedGroup;
@property (strong) NSString *DetectedType;
@property (strong, getter=getFailedTitle) NSString *FailedTitle;
@property (strong, getter=getFailedEpisode) NSString *FailedEpisode;
@property (strong) NSString *FailedSource;
@property (getter=getFailedSeason) int FailedSeason;
@property int DetectedSeason;
@property (getter=getCurrentEpisode) int DetectedCurrentEpisode;
@property BOOL DetectedTitleisMovie;
@property BOOL DetectedTitleisEpisodeZero;
@property (getter=getTotalEpisodes) int TotalEpisodes;
@property (strong) NSString *WatchStatus;
@property (getter=getTitleScore) int TitleScore;
@property long rewatchcount;
@property (getter=getRewatching) BOOL rewatching;
@property (strong, getter=getNotes) NSString *TitleNotes;
@property (strong, getter=getAniID) NSString *AniID;
@property (strong) NSString *EntryID;
@property (strong) NSString *MALID;
@property (strong) NSString *MALApiUrl;
@property (strong, getter=getSlug) NSString *slug;
@property (getter=getConfirmed) BOOL confirmed;
@property (getter=getSuccess) BOOL Success;
@property BOOL correcting;
@property BOOL unittesting;
@property (strong) Reachability* reach;
@property (strong, setter=setManagedObjectContext:) NSManagedObjectContext *managedObjectContext;
@property (getter=getOnlineStatus) bool online;
@property (getter=getRatingType) int ratingtype;
@property (strong) Detection *detection;
@property (strong) TwitterManager *twittermanager;
@property (strong) DiscordManager *discordmanager;

- (void)setManagedObjectContext:(NSManagedObjectContext *)context;
- (int)getWatchStatus;
- (int)getQueueCount;
- (long)currentService;
- (NSString *)currentServiceName;
- (AFOAuthCredential *)getCurrentFirstAccount;
- (AFOAuthCredential *)getFirstAccount:(long)service;
- (NSString *)getUserid;
- (int)startscrobbling;
- (NSDictionary *)scrobblefromqueue;
- (int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)onetime;
- (int)scrobble;
- (BOOL)confirmupdate;
- (void)clearAnimeInfo;
- (bool)checkexpired;
- (void)refreshtokenWithService:(int)service successHandler:(void (^)(bool success)) successHandler;
- (void)retrieveUserID:(void (^)(int userid, NSString *username, NSString *scoreformat)) completionHandler error:(void (^)(NSError * error)) errorHandler withService:(int)service;
- (void)resetinfo;
- (void)setNotifier;
// Unit Testing Only
- (NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season group:(NSString *)group type:(NSString *)type;
@end
