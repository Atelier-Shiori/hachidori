//
//  KitsuUpdateManager.h
//  Hachidori
//
//  Created by 香風智乃 on 1/15/19.
//

#import <Foundation/Foundation.h>

@class AFHTTPSessionManager;
@class LastScrobbleStatus;
@class DetectedScrobbleStatus;

@interface KitsuUpdateManager : NSObject
@property (strong) AFHTTPSessionManager *syncmanager;
@property (strong) AFHTTPSessionManager *asyncmanager;
@property (strong) DetectedScrobbleStatus *detectedscrobble;
@property (strong) LastScrobbleStatus *lastscrobble;
- (int)kitsuperformupdate:(NSString *)titleid;
- (void)kitsuupdatestatus:(NSString *)titleid
                  episode:(NSString *)episode
                    score:(int)showscore
              watchstatus:(NSString*)showwatchstatus
                    notes:(NSString*)note
                isPrivate:(BOOL)privatevalue
               completion:(void (^)(bool success))completionhandler;
- (BOOL)kitsustopRewatching:(NSString *)titleid;
- (bool)kitsuremovetitle:(NSString *)titleid;
- (void)kitsustoreLastScrobbled;
@end

