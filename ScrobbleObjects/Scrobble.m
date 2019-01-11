//
//  Scrobble.m
//  Hachidori
//
//  Created by 香風智乃 on 1/9/19.
//

#import "Scrobble.h"

@implementation Scrobble
- (int)getWatchStatus {
    if ([_WatchStatus isEqualToString:@"watching"]) {
        return 0;
    }
    else if ([_WatchStatus isEqualToString:@"completed"]) {
        return 1;
    }
    else if ([_WatchStatus isEqualToString:@"on-hold"]) {
        return 2;
    }
    else if ([_WatchStatus isEqualToString:@"dropped"]) {
        return 3;
    }
    else if ([_WatchStatus isEqualToString:@"plan-to-watch"]) {
        return 4;
    }
    else {
        return 0; //fallback
    }
}
@end
