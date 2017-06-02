//
//  Hachidori.h
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>
#import <AFNetworking/AFOAuth2Manager.h>
#import <streamlinkdetect/streamlinkdetect.h>
@class Reachability;
@class Detection;

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
typedef NS_ENUM(unsigned int, ratingType){
    ratingSimple = 0,
    ratingStandard = 1,
    ratingAdvanced = 2
};
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
@property (strong) NSString *DetectedTitle;
@property (strong) NSString *DetectedEpisode;
@property (strong) NSString *DetectedSource;
@property (strong) NSString *DetectedGroup;
@property (strong) NSString *DetectedType;
@property (strong, getter=getFailedTitle) NSString *FailedTitle;
@property (strong, getter=getFailedEpisode) NSString *FailedEpisode;
@property (strong) NSString *FailedSource;
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
@property (strong) NSManagedObjectContext *managedObjectContext;
@property (strong) streamlinkdetector *detector;
@property (getter=getOnlineStatus) bool online;
@property (getter=getRatingType) int ratingtype;
@property (strong) Detection *detection;
- (void)setManagedObjectContext:(NSManagedObjectContext *)context;
- (int)getWatchStatus;
- (int)getQueueCount;
- (AFOAuthCredential *)getFirstAccount;
- (NSString *)getUserid;
- (int)startscrobbling;
- (NSDictionary *)scrobblefromqueue;
- (int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)onetime;
- (int)scrobblefromstreamlink:(NSString *)url withStream:(NSString *)stream;
- (int)scrobble;
- (BOOL)confirmupdate;
- (void)clearAnimeInfo;
- (bool)checkexpired;
- (void)refreshtoken;
- (void)resetinfo;
// Unit Testing Only
- (NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season group:(NSString *)group type:(NSString *)type;
@end
