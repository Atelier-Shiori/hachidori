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
    BOOL LastScrobbledTitleNew;
    BOOL isPrivate;
    BOOL online;
    NSDictionary * LastScrobbledInfo;
	NSString * DetectedTitle;
	NSString * DetectedEpisode;
    int DetectedSeason;
	NSString * DetectedCurrentEpisode;
    BOOL DetectedTitleisMovie;
	NSString * TotalEpisodes;
	NSString * WatchStatus;
	NSString * TitleScore;
	NSString * TitleState;
    NSString * TitleNotes;
    NSString * AniID;
    BOOL confirmed;
    BOOL DetectedisStream;
	BOOL Success;
    BOOL correcting;
	int choice;
    BOOL unittesting;
}
-(NSString *)getLastScrobbledTitle;
-(NSString *)getLastScrobbledEpisode;
-(NSString *)getLastScrobbledActualTitle;
-(NSString *)getAniID;
-(NSString *)getTotalEpisodes;
-(int)getCurrentEpisode;
-(int)getScore;
-(int)getWatchStatus;
-(NSString *)getNotes;
-(BOOL)getSuccess;
-(BOOL)getPrivate;
-(BOOL)getisNewTitle;
-(NSDictionary *)getLastScrobbledInfo;
-(BOOL)checktoken;
-(int)startscrobbling;
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode;
-(int)scrobble;
-(BOOL)confirmupdate;
-(BOOL)updatestatus:(NSString *)titleid
            episode:(NSString *)episode
              score:(float)showscore
        watchstatus:(NSString*)showwatchstatus
              notes:(NSString*)note
          isPrivate:(BOOL)privatevalue;
-(bool)removetitle:(NSString *)titleid;
-(void)clearAnimeInfo;
// Unit Testing Only
-(NSDictionary *)runUnitTest:(NSString *)title episode:(NSString *)episode season:(int)season;
@end
