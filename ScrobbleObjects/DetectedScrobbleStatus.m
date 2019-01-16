//
//  DetectedScrobbleStatus.m
//  Hachidori
//
//  Created by 香風智乃 on 1/8/19.
//

#import "DetectedScrobbleStatus.h"

@implementation DetectedScrobbleStatus
- (void)checkzeroEpisode {
    // For 00 Episodes
    if ([_DetectedEpisode isEqualToString:@"00"]||[_DetectedEpisode isEqualToString:@"0"]) {
        _DetectedEpisode = @"1";
        self.DetectedTitleisEpisodeZero = true;
    }
    else if (([_DetectedType isLike:@"Movie"] || [_DetectedType isLike:@"OVA"] || [_DetectedType isLike:@"Special"]) && ([_DetectedEpisode isEqualToString:@"0"] || _DetectedEpisode.length == 0)) {
        _DetectedEpisode = @"1";
    }
    else {
        self.DetectedTitleisEpisodeZero = false;
    }
}
- (id)copyWithZone:(NSZone *)zone {
    DetectedScrobbleStatus *detectedscrobblecopy = [[DetectedScrobbleStatus allocWithZone:zone] init];
    detectedscrobblecopy.DetectedTitle = _DetectedTitle;
    detectedscrobblecopy.DetectedEpisode = _DetectedEpisode;
    detectedscrobblecopy.DetectedSource = _DetectedSource;
    detectedscrobblecopy.DetectedGroup = _DetectedGroup;
    detectedscrobblecopy.DetectedType = _DetectedType;
    detectedscrobblecopy.FailedTitle = _FailedTitle;
    detectedscrobblecopy.FailedEpisode = _FailedEpisode;
    detectedscrobblecopy.FailedSource = _FailedSource;
    detectedscrobblecopy.DetectedSeason = self.DetectedSeason;
    detectedscrobblecopy.DetectedTitleisMovie = self.DetectedTitleisMovie;
    detectedscrobblecopy.DetectedTitleisEpisodeZero = self.DetectedTitleisEpisodeZero;
    return detectedscrobblecopy;
}
@end
