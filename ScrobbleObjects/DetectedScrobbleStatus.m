//
//  DetectedScrobbleStatus.m
//  Hachidori
//
//  Created by 香風智乃 on 1/8/19.
//

#import "DetectedScrobbleStatus.h"
#import "LastScrobbleStatus.h"

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

- (void)transferLastScrobbled:(LastScrobbleStatus *)lscrobbled {
    self.DetectedTitle = lscrobbled.LastScrobbledTitle;
    self.DetectedEpisode = lscrobbled.LastScrobbledEpisode;
    self.DetectedSource = lscrobbled.LastScrobbledSource;
    self.DetectedCurrentEpisode = lscrobbled.DetectedCurrentEpisode;
    self.LastScrobbledInfo = lscrobbled.LastScrobbledInfo;
    self.LastScrobbledTitleNew = lscrobbled.LastScrobbledTitleNew;
    self.isPrivate = lscrobbled.isPrivate;
    self.startDate = lscrobbled.startDate;
    self.endDate = lscrobbled.endDate;
    self.airing = lscrobbled.airing;
    self.completedairing = lscrobbled.completedairing;
    self.TotalEpisodes = lscrobbled.TotalEpisodes;
    self.DetectedTitleisMovie = lscrobbled.DetectedTitleisMovie;
    self.DetectedTitleisEpisodeZero = lscrobbled.DetectedTitleisEpisodeZero;
    self.WatchStatus = lscrobbled.WatchStatus;
    self.TitleScore = lscrobbled.TitleScore;
    self.rewatchcount = lscrobbled.rewatchcount;
    self.rewatching = lscrobbled.rewatching;
    self.TitleNotes = lscrobbled.TitleNotes;
    self.AniID = lscrobbled.AniID;
    self.EntryID = lscrobbled.EntryID;
    self.slug = lscrobbled.slug;
    self.confirmed = lscrobbled.confirmed;
}
@end
