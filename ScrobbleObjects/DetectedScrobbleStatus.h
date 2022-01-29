//
//  DetectedScrobbleStatus.h
//  Hachidori
//
//  Created by 香風智乃 on 1/8/19.
//

#import <Foundation/Foundation.h>
#import "Scrobble.h"
@class LastScrobbleStatus;
@interface DetectedScrobbleStatus : Scrobble <NSCopying>
    @property (strong) NSString *DetectedTitle;
    @property (strong) NSString *DetectedEpisode;
    @property (strong) NSString *DetectedSource;
    @property (strong) NSString *DetectedGroup;
    @property (strong) NSString *DetectedType;
    @property (strong, getter=getFailedTitle) NSString *FailedTitle;
    @property (strong, getter=getFailedEpisode) NSString *FailedEpisode;
    @property (strong) NSString *FailedSource;
    @property (getter=getFailedSeason) int FailedSeason;
    @property bool corrected;
    - (void)checkzeroEpisode;
    - (void)transferLastScrobbled:(LastScrobbleStatus *)lscrobbled;
@end

