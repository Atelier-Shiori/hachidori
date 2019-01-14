//
//  HachidoriTwitterManager.h
//  Hachidori
//
//  Created by 香風智乃 on 1/14/19.
//

#import <Foundation/Foundation.h>
@class TwitterManager;
@class LastScrobbleStatus;

NS_ASSUME_NONNULL_BEGIN

@interface HachidoriTwitterManager : NSObject
@property (strong) TwitterManager *twittermanager;
- (void)postaddanimetweet:(LastScrobbleStatus *)lastscrobbled;
- (void)postupdateanimetweet:(LastScrobbleStatus *)lastscrobbled;
- (void)postupdatestatustweet:(LastScrobbleStatus *)lastscrobbled;
@end

NS_ASSUME_NONNULL_END
