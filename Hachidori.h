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
    int LastScrobbledSeason;
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
    NSString * FailedTitle;
    NSString * FailedEpisode;
    BOOL DetectedisStream;
	BOOL Success;
	int choice;
}
-(int)startscrobbling;
-(int)scrobbleagain:(NSString *)showtitle Episode:(NSString *)episode;
-(int)scrobble;
-(int)detectmedia; // 0 - Nothing, 1 - Same, 2 - Update
-(NSString *)searchanime;
-(NSString *)findaniid:(NSData *)ResponseData;
-(BOOL)checkstatus:(NSString *)titleid;
-(NSDictionary *)retrieveAnimeInfo:(NSString *)slug;
-(int)updatetitle:(NSString *)titleid;
-(BOOL)updatestatus:(NSString *)titleid
              score:(float)showscore
        watchstatus:(NSString*)showwatchstatus
              notes:(NSString*)note
          isPrivate:(BOOL)privatevalue;
-(bool)removetitle:(NSString *)titleid;
-(NSString *)getLastScrobbledTitle;
-(NSString *)getLastScrobbledEpisode;
-(NSString *)getAniID;
-(NSString *)getTotalEpisodes;
-(int)getScore;
-(int)getWatchStatus;
-(NSString *)getNotes;
-(BOOL)getSuccess;
-(BOOL)getPrivate;
-(NSDictionary *)getLastScrobbledInfo;
-(NSDictionary *)detectStream;
-(void)populateStatusData:(NSDictionary *)d;
-(int)recognizeSeason:(NSString *)season;
-(int)countWordsInTitle:(NSString *) title;
-(void)addtoCache:(NSString *)title showid:(NSString *)showid;
@end
