//
//  Hachidori.h
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import <ASIHTTPRequest/ASIHTTPRequest.h>
#import <ASIHTTPRequest/ASIFormDataRequest.h>

@interface Hachidori : NSObject {
	NSString * Token;
	NSString * LastScrobbledTitle;
	NSString * LastScrobbledEpisode;
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
    BOOL DetectedisStream;
	BOOL Success;
	int choice;
}
-(int)startscrobbling;
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode;
-(int)scrobble;
-(BOOL)updatestatus:(NSString *)titleid
            episode:(NSString *)episode
              score:(float)showscore
        watchstatus:(NSString*)showwatchstatus
              notes:(NSString*)note
          isPrivate:(BOOL)privatevalue;
-(bool)removetitle:(NSString *)titleid;
-(NSString *)getLastScrobbledTitle;
-(NSString *)getLastScrobbledEpisode;
-(NSString *)getAniID;
-(NSString *)getTotalEpisodes;
-(int)getCurrentEpisode;
-(int)getScore;
-(int)getWatchStatus;
-(NSString *)getNotes;
-(BOOL)getSuccess;
-(BOOL)getPrivate;
-(NSDictionary *)getLastScrobbledInfo;
-(void)clearAnimeInfo;
@end
