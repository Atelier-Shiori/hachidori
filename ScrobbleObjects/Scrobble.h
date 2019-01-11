//
//  Scrobble.h
//  Hachidori
//
//  Created by 香風智乃 on 1/9/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Scrobble : NSObject
@property (strong, getter=getLastScrobbledActualTitle) NSString *LastScrobbledActualTitle;
@property (strong, getter=getLastScrobbledInfo) NSDictionary *LastScrobbledInfo;
@property (getter=getisNewTitle) BOOL LastScrobbledTitleNew;
@property (getter=getPrivate) BOOL isPrivate;
@property (strong) NSString *startDate;
@property (strong) NSString *endDate;
@property bool airing;
@property bool completedairing;
@property (getter=getTotalEpisodes) int TotalEpisodes;
@property int DetectedSeason;
@property (getter=getCurrentEpisode) int DetectedCurrentEpisode;
@property BOOL DetectedTitleisMovie;
@property BOOL DetectedTitleisEpisodeZero;
@property (strong) NSString *WatchStatus;
@property (getter=getTitleScore) int TitleScore;
@property long rewatchcount;
@property (getter=getRewatching) BOOL rewatching;
@property (strong, getter=getNotes) NSString *TitleNotes;
@property (strong, getter=getAniID) NSString *AniID;
@property (strong) NSString *EntryID;
@property (strong, getter=getSlug) NSString *slug;
@property (getter=getConfirmed) BOOL confirmed;
- (int)getWatchStatus;
@end

NS_ASSUME_NONNULL_END
