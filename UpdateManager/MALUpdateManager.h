//
//  MALUpdateManager.h
//  Hachidori
//
//  Created by 香風智乃 on 8/30/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AFHTTPSessionManager;
@class LastScrobbleStatus;
@class DetectedScrobbleStatus;

@interface MALUpdateManager : NSObject
@property (strong) AFHTTPSessionManager *syncmanager;
@property (strong) AFHTTPSessionManager *asyncmanager;
@property (strong) DetectedScrobbleStatus *detectedscrobble;
@property (strong) LastScrobbleStatus *lastscrobble;
- (int)malperformupdate:(NSString *)titleid;
- (void)malupdatestatus:(NSString *)titleid
                  episode:(NSString *)episode
                    score:(int)showscore
              watchstatus:(NSString*)showwatchstatus
                    notes:(NSString*)note
               completion:(void (^)(bool success))completionhandler;
- (BOOL)malstopRewatching:(NSString *)titleid;
- (bool)malremovetitle:(NSString *)titleid;
- (void)malstoreLastScrobbled;
@end

NS_ASSUME_NONNULL_END
