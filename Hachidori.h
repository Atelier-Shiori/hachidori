//
//  Hachidori.h
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import <AFNetworking/AFOAuth2Manager.h>
@class Reachability;

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
	__weak NSString * DetectedTitle;
	__weak NSString * DetectedEpisode;
    __weak NSString * DetectedSource;
    __weak NSString * DetectedGroup;
    __weak NSString * DetectedType;
    NSString * FailedTitle;
    NSString * FailedEpisode;
    NSString * FailedSource;
    int DetectedSeason;
	int DetectedCurrentEpisode;
    BOOL DetectedTitleisMovie;
    BOOL DetectedTitleisEpisodeZero;
	int TotalEpisodes;
	NSString * WatchStatus;
	float TitleScore;
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
    Reachability* kodireach;
	NSManagedObjectContext *managedObjectContext;
}
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (getter=getOnlineStatus) bool online;
@property (getter=getKodiOnlineStatus) bool kodionline;
-(void)setManagedObjectContext:(NSManagedObjectContext *)context;
-(NSString *)getLastScrobbledTitle;
-(NSString *)getLastScrobbledEpisode;
-(NSString *)getLastScrobbledActualTitle;
-(NSString *)getLastScrobbledSource;
-(NSString *)getAniID;
-(int)getTotalEpisodes;
-(int)getCurrentEpisode;
-(BOOL)getConfirmed;
-(float)getScore;
-(int)getWatchStatus;
-(BOOL)getRewatching;
-(NSString *)getNotes;
-(BOOL)getSuccess;
-(BOOL)getPrivate;
-(BOOL)getisNewTitle;
-(NSDictionary *)getLastScrobbledInfo;
-(NSString *)getFailedTitle;
-(NSString *)getFailedEpisode;
-(int)getQueueCount;
-(int)startscrobbling;
-(NSDictionary *)scrobblefromqueue;
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)onetime;
-(int)scrobble;
-(BOOL)confirmupdate;
-(void)clearAnimeInfo;
-(AFOAuthCredential *)getFirstAccount;
-(NSString *)getUserid;
-(NSString *)getSlug;
-(void)setKodiReach:(BOOL)enable;
-(void)setKodiReachAddress:(NSString *)url;
-(bool)checkexpired;
-(void)refreshtoken;
// Unit Testing Only
-(NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season group:(NSString *)group type:(NSString *)type;
@end
