//
//  AniListUpdateManager.h
//  Hachidori
//
//  Created by 香風智乃 on 1/15/19.
//

#import <Foundation/Foundation.h>

@class AFHTTPSessionManager;
@class LastScrobbleStatus;
@class DetectedScrobbleStatus;

@interface AniListUpdateManager : NSObject
@property (strong) AFHTTPSessionManager *syncmanager;
@property (strong) AFHTTPSessionManager *asyncmanager;
@property (strong) DetectedScrobbleStatus *detectedscrobble;
@property (strong) LastScrobbleStatus *lastscrobble;
- (int)anilistperformupdate:(NSString *)titleid;
- (void)anilistupdatestatus:(NSString *)titleid
                    episode:(NSString *)episode
                      score:(int)showscore
                watchstatus:(NSString*)showwatchstatus
                      notes:(NSString*)note
                  isPrivate:(BOOL)privatevalue
                 completion:(void (^)(bool success))completionhandler;
- (BOOL)aniliststopRewatching:(NSString *)titleid;
- (bool)anilistremovetitle:(NSString *)titleid;
- (void)aniliststoreLastScrobbled;
@end

