//
//  Hachidori+MultiScrobble.h
//  Hachidori
//
//  Created by 香風智乃 on 1/14/19.
//

#import "Hachidori.h"

NS_ASSUME_NONNULL_BEGIN

@interface Hachidori (MultiScrobble)
typedef NS_ENUM(unsigned int, MultiScrobbleType) {
    MultiScrobbleTypeScrobble = 1,
    MultiScrobbleTypeEntryupdate = 2,
    MultiScrobbleTypeCorrection = 3
};
- (void)multiscrobbleWithType:(MultiScrobbleType)scrobbletype withTitleID:(NSString *)titleid;
@end

NS_ASSUME_NONNULL_END
