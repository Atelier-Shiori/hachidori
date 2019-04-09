//
//  LastScrobbleStatus.m
//  Hachidori
//
//  Created by 香風智乃 on 1/8/19.
//

#import "LastScrobbleStatus.h"
#import "DetectedScrobbleStatus.h"

@implementation LastScrobbleStatus
- (void)transferDetectedScrobble:(DetectedScrobbleStatus *)detected {
    self.LastScrobbledTitle = detected.DetectedTitle;
    self.LastScrobbledEpisode = detected.DetectedEpisode;
    self.LastScrobbledSource = detected.DetectedSource;
    self.DetectedCurrentEpisode = detected.DetectedCurrentEpisode;
    self.LastScrobbledInfo = detected.LastScrobbledInfo;
    self.LastScrobbledTitleNew = detected.LastScrobbledTitleNew;
    self.isPrivate = detected.isPrivate;
    self.startDate = detected.startDate;
    self.endDate = detected.endDate;
    self.airing = detected.airing;
    self.completedairing = detected.completedairing;
    self.TotalEpisodes = detected.TotalEpisodes;
    self.DetectedTitleisMovie = detected.DetectedTitleisMovie;
    self.DetectedTitleisEpisodeZero = detected.DetectedTitleisEpisodeZero;
    self.WatchStatus = detected.WatchStatus;
    self.TitleScore = detected.TitleScore;
    self.rewatchcount = detected.rewatchcount;
    self.rewatching = detected.rewatching;
    self.TitleNotes = detected.TitleNotes;
    self.AniID = detected.AniID;
    self.EntryID = detected.EntryID;
    self.slug = detected.slug;
    self.confirmed = detected.confirmed;
}
@end
