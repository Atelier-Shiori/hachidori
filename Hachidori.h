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

@interface Hachidori : NSObject {
	NSString * LastScrobbledTitle;
	NSString * LastScrobbledEpisode;
    NSString * LastScrobbledActualTitle;
    NSString * LastScrobbledSource;
    NSString * username;
    NSString * malusername;
	NSDictionary * LastScrobbledInfo;
    BOOL LastScrobbledTitleNew;
    BOOL isPrivate;
    BOOL _online;
	NSString * DetectedTitle;
    NSString * DetectedEpisode;
    NSString * DetectedSource;
    NSString * DetectedGroup;
    NSString * DetectedType;
    NSString * FailedTitle;
    NSString * FailedEpisode;
    NSString * FailedSource;
    int DetectedSeason;
	int DetectedCurrentEpisode;
    BOOL DetectedTitleisMovie;
    BOOL DetectedTitleisEpisodeZero;
	int TotalEpisodes;
	NSString * WatchStatus;
	int TitleScore;
    long rewatchcount;
    BOOL rewatching;
    NSString * TitleNotes;
    NSString * AniID;
    NSString * EntryID;
    NSString * MALID;
    NSString * MALApiUrl;
    NSString * slug;
    BOOL confirmed;
	BOOL Success;
    BOOL correcting;
    BOOL unittesting;
    Reachability* reach;
	NSManagedObjectContext *managedObjectContext;
    streamlinkdetector * detector;
}
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
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (getter=getOnlineStatus) bool online;
@property (getter=getRatingType) int ratingtype;
@property (strong) Detection *detection;
- (void)setManagedObjectContext:(NSManagedObjectContext *)context;
- (NSString *)getLastScrobbledTitle;
- (NSString *)getLastScrobbledEpisode;
- (NSString *)getLastScrobbledActualTitle;
- (NSString *)getLastScrobbledSource;
- (NSString *)getAniID;
- (int)getTotalEpisodes;
- (int)getCurrentEpisode;
- (BOOL)getConfirmed;
- (float)getScore;
- (int)getWatchStatus;
- (BOOL)getRewatching;
- (NSString *)getNotes;
- (BOOL)getSuccess;
- (BOOL)getPrivate;
- (BOOL)getisNewTitle;
- (NSDictionary *)getLastScrobbledInfo;
- (NSString *)getFailedTitle;
- (NSString *)getFailedEpisode;
- (int)getQueueCount;
- (int)startscrobbling;
- (NSDictionary *)scrobblefromqueue;
- (int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)onetime;
- (int)scrobblefromstreamlink:(NSString *)url withStream:(NSString *)stream;
- (int)scrobble;
- (BOOL)confirmupdate;
- (void)clearAnimeInfo;
- (AFOAuthCredential *)getFirstAccount;
- (NSString *)getUserid;
- (NSString *)getSlug;
- (bool)checkexpired;
- (void)refreshtoken;
// Unit Testing Only
- (NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season group:(NSString *)group type:(NSString *)type;
@end
