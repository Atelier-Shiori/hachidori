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
    NSDictionary * LastScrobbledInfo;
	NSString * DetectedTitle;
	NSString * DetectedEpisode;
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
- (int)startscrobbling;
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
@end
