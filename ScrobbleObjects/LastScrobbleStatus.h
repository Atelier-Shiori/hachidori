//
//  LastScrobbleStatus.h
//  Hachidori
//
//  Created by 香風智乃 on 1/8/19.
//

#import <Foundation/Foundation.h>
#import "Scrobble.h"

@class DetectedScrobbleStatus;

@interface LastScrobbleStatus : Scrobble
@property (strong, getter=getLastScrobbledTitle) NSString *LastScrobbledTitle;
@property (strong, getter=getLastScrobbledEpisode) NSString *LastScrobbledEpisode;
@property (strong, getter=getLastScrobbledSource) NSString *LastScrobbledSource;
- (void)transferDetectedScrobble:(DetectedScrobbleStatus *)detected;
@end
