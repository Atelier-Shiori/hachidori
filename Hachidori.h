//
//  Hachidori.h
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

@interface Hachidori : NSObject {
	NSString * LastScrobbledTitle;
	NSString * LastScrobbledEpisode;
    NSString * LastScrobbledActualTitle;
    NSString * LastScrobbledSource;
	NSDictionary * LastScrobbledInfo;
    BOOL LastScrobbledTitleNew;
    BOOL isPrivate;
    BOOL online;
	__weak NSString * DetectedTitle;
	__weak NSString * DetectedEpisode;
    __weak NSString * DetectedSource;
    __weak NSString * DetectedGroup;
    NSString * FailedTitle;
    NSString * FailedEpisode;
    NSString * FailedSource;
    int DetectedSeason;
	int DetectedCurrentEpisode;
    BOOL DetectedTitleisMovie;
	int TotalEpisodes;
	NSString * WatchStatus;
	float TitleScore;
    NSString * TitleNotes;
    NSString * AniID;
    BOOL confirmed;
	BOOL Success;
    BOOL correcting;
    BOOL unittesting;
	NSManagedObjectContext *managedObjectContext;
}
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
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
-(NSString *)getNotes;
-(BOOL)getSuccess;
-(BOOL)getPrivate;
-(BOOL)getisNewTitle;
-(NSDictionary *)getLastScrobbledInfo;
-(NSString *)getFailedTitle;
-(NSString *)getFailedEpisode;
-(int)startscrobbling;
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode correctonce:(BOOL)onetime;
-(int)scrobble;
-(BOOL)confirmupdate;
-(void)clearAnimeInfo;
// Unit Testing Only
-(NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season group:(NSString *)group;
@end
