//
//  AtarashiiAPIListFormatAniList.m
//  Shukofukurou
//
//  Created by 天々座理世 on 2018/03/27.
//  Copyright © 2018年 MAL Updater OS X Group. All rights reserved.
//

#import "AtarashiiAPIListFormatAniList.h"
#import "AtarashiiDataObjects.h"
#import "Utility.h"
#import "NSString_stripHtml.h"

@implementation AtarashiiAPIListFormatAniList
+ (id)AniListtoAtarashiiAnimeSingle:(id)data {
    for (NSDictionary *entry in data) {
        @autoreleasepool{
            // Create the entry in a standardized format
            AtarashiiAnimeListObject *aentry = [AtarashiiAnimeListObject new];
            aentry.titleid = ((NSNumber *)entry[@"id"][@"id"]).intValue;
            aentry.entryid = ((NSNumber *)entry[@"entryid"]).intValue;
            aentry.score = ((NSNumber *)entry[@"score"]).intValue;
            aentry.watched_episodes = ((NSNumber *)entry[@"watched_episodes"]).intValue;
            if ([(NSString *)entry[@"watched_status"] isEqualToString:@"PAUSED"]) {
                aentry.watched_status = @"on-hold";
            }
            else if ([(NSString *)entry[@"watched_status"] isEqualToString:@"PLANNING"]) {
                aentry.watched_status = @"plan to watch";
            }
            else if ([(NSString *)entry[@"watched_status"] isEqualToString:@"CURRENT"]) {
                aentry.watched_status = @"watching";
            }
            else if ([(NSString *)entry[@"watched_status"] isEqualToString:@"REPEATING"]) {
                aentry.watched_status = @"watching";
                aentry.rewatching = true;
            }
            else {
                aentry.watched_status = ((NSString *)entry[@"watched_status"]).lowercaseString;
            }
            aentry.rewatch_count =  ((NSNumber *)entry[@"rewatch_count"]).intValue;
            aentry.private_entry =  ((NSNumber *)entry[@"private"]).boolValue;
            aentry.personal_comments = entry[@"notes"];
            aentry.watching_start = entry[@"watching_start"][@"year"] != [NSNull null] && entry[@"watching_start"][@"year"] != [NSNull null] && entry[@"watching_start"][@"year"] != [NSNull null] ? [self convertDate:entry[@"watching_start"]] : @"";
            aentry.watching_end = entry[@"watching_end"][@"year"] != [NSNull null] && entry[@"watching_end"][@"year"] != [NSNull null] && entry[@"watching_end"][@"year"] != [NSNull null] ? [self convertDate:entry[@"watching_end"]] : @"";
            return [aentry NSDictionaryRepresentation].copy;
        }
    }
    return nil;
}

+ (NSDictionary *)AniListAnimeInfotoAtarashii:(NSDictionary *)data {
    AtarashiiAnimeObject *aobject = [AtarashiiAnimeObject new];
    NSDictionary *title = data[@"data"][@"Media"];
    aobject.titleid = ((NSNumber *)title[@"id"]).intValue;
    aobject.title = title[@"title"][@"romaji"];
    // Create other titles
    aobject.other_titles = @{@"synonyms" : title[@"synonyms"] && title[@"synonyms"] != [NSNull null] ? title[@"synonyms"] : @[]  , @"english" : title[@"title"][@"english"] != [NSNull null] && title[@"title"][@"english"] ? @[title[@"title"][@"english"]] : @[], @"japanese" : title[@"title"][@"native"] != [NSNull null] && title[@"title"][@"native"] ? @[title[@"title"][@"native"]] : @[] };
    aobject.popularity_rank = title[@"popularity"] != [NSNull null] ? ((NSNumber *)title[@"popularity"]).intValue : 0;
    #if defined(AppStore)
    if (title[@"coverImage"] != [NSNull null]) {
        aobject.image_url = title[@"coverImage"][@"large"] && title[@"coverImage"] != [NSNull null] && !((NSNumber *)title[@"isAdult"]).boolValue ? title[@"coverImage"][@"large"] : @"";
    }
    aobject.synposis = !((NSNumber *)title[@"isAdult"]).boolValue ? title[@"description"] != [NSNull null] ? [(NSString *)title[@"description"] stripHtml] : @"No synopsis available" : @"Synopsis not available for adult titles";
    #else
    bool allowed = ([NSUserDefaults.standardUserDefaults boolForKey:@"showadult"] || !((NSNumber *)title[@"isAdult"]).boolValue);
    if (title[@"coverImage"] != [NSNull null]) {
        aobject.image_url = title[@"coverImage"][@"large"] && title[@"coverImage"] != [NSNull null] && title[@"coverImage"][@"large"] && allowed ?  title[@"coverImage"][@"large"] : @"";
    }
        aobject.synposis = allowed ?  title[@"description"] != [NSNull null] ? [(NSString *)title[@"description"] stripHtml] : @"No synopsis available" : @"Synopsis not available for adult titles";
    #endif
    aobject.type = title[@"format"] != [NSNull null] ? [Utility convertAnimeType:title[@"format"]] : @"";
    aobject.episodes = title[@"episodes"] != [NSNull null] ? ((NSNumber *)title[@"episodes"]).intValue : 0;
    aobject.start_date = title[@"startDate"][@"year"] != [NSNull null] && title[@"startDate"][@"month"] != [NSNull null] && title[@"startDate"][@"day"] != [NSNull null] ? [NSString stringWithFormat:@"%@-%@-%@",title[@"startDate"][@"year"],((NSNumber *)title[@"startDate"][@"month"]).intValue < 10 ? [NSString stringWithFormat:@"0%i",((NSNumber *)title[@"startDate"][@"month"]).intValue] : title[@"startDate"][@"month"],((NSNumber *)title[@"startDate"][@"day"]).intValue < 10 ? [NSString stringWithFormat:@"0%i",((NSNumber *)title[@"startDate"][@"day"]).intValue] : title[@"startDate"][@"day"]] : @"";
    aobject.end_date = title[@"endDate"][@"year"] != [NSNull null] && title[@"endDate"][@"month"] != [NSNull null] && title[@"endDate"][@"day"] != [NSNull null] ? [NSString stringWithFormat:@"%@-%@-%@",title[@"endDate"][@"year"],((NSNumber *)title[@"endDate"][@"month"]).intValue < 10 ? [NSString stringWithFormat:@"0%i",((NSNumber *)title[@"endDate"][@"month"]).intValue] : title[@"endDate"][@"month"],((NSNumber *)title[@"endDate"][@"day"]).intValue < 10 ? [NSString stringWithFormat:@"0%i",((NSNumber *)title[@"endDate"][@"day"]).intValue] : title[@"endDate"][@"day"]] : @"";
    aobject.duration = title[@"duration"] != [NSNull null] ? ((NSNumber *)title[@"duration"]).intValue : 0;
    aobject.classification = @"None available";
    aobject.members_score = title[@"averageScore"] != [NSNull null] ? ((NSNumber *)title[@"averageScore"]).floatValue : 0;
    NSString *tmpstatus  = title[@"status"] != [NSNull null] ? title[@"status"] : @"NOT_YET_RELEASED";
    if ([tmpstatus isEqualToString:@"FINISHED"]||[tmpstatus isEqualToString:@"CANCELLED"]) {
        tmpstatus = @"finished airing";
    }
    else if ([tmpstatus isEqualToString:@"RELEASING"]) {
        tmpstatus = @"currently airing";
    }
    else if ([tmpstatus isEqualToString:@"NOT_YET_RELEASED"]) {
        tmpstatus = @"not yet aired";
    }
    aobject.status = tmpstatus;
    NSMutableArray *genres = [NSMutableArray new];
    for (NSString *genre in title[@"genres"]) {
        [genres addObject:genre];
    }
    aobject.genres = genres;
    if (title[@"idMal"]) {
        aobject.mappings = @{@"myanimelist/anime" : title[@"idMal"]};
    }
    NSMutableArray *mangaadaptations = [NSMutableArray new];
    for (NSDictionary *adpt in [(NSArray *)title[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"ADAPTATION"]]) {
        if ([(NSString *)adpt[@"node"][@"type"] isEqualToString:@"MANGA"]) {
            [mangaadaptations addObject: @{@"manga_id": adpt[@"node"][@"id"], @"title" : adpt[@"node"][@"title"][@"romaji"]}];
        }
    }
    NSMutableArray *sidestories = [NSMutableArray new];
    for (NSDictionary *side in [(NSArray *)title[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"SIDE_STORY"]]) {
        if ([(NSString *)side[@"node"][@"type"] isEqualToString:@"ANIME"]) {
            [sidestories addObject: @{@"anime_id": side[@"node"][@"id"], @"title" : side[@"node"][@"title"][@"romaji"]}];
        }
    }
    NSMutableArray *sequels = [NSMutableArray new];
    for (NSDictionary *sequel in [(NSArray *)title[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"SEQUEL"]]) {
        if ([(NSString *)sequel[@"node"][@"type"] isEqualToString:@"ANIME"]) {
            [sequels addObject: @{@"anime_id": sequel[@"node"][@"id"], @"title" : sequel[@"node"][@"title"][@"romaji"]}];
        }
    }
    NSMutableArray *prequels = [NSMutableArray new];
    for (NSDictionary *prequel in [(NSArray *)title[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"PREQUEL"]]) {
        if ([(NSString *)prequel[@"node"][@"type"] isEqualToString:@"ANIME"]) {
            [prequels addObject: @{@"anime_id": prequel[@"node"][@"id"], @"title" : prequel[@"node"][@"title"][@"romaji"]}];
        }
    }
    aobject.manga_adaptations = mangaadaptations;
    aobject.side_stories = sidestories;
    aobject.sequels = sequels;
    aobject.prequels = prequels;

    return aobject.NSDictionaryRepresentation;
}
+ (NSArray *)AniListAnimeSearchtoAtarashii:(NSDictionary *)data {
    NSArray *dataarray = data[@"data"][@"Page"][@"media"];
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSDictionary *d in dataarray) {
        @autoreleasepool {
            AtarashiiAnimeObject *aobject = [AtarashiiAnimeObject new];
            aobject.titleid = ((NSNumber *)d[@"id"]).intValue;
            aobject.title = d[@"title"][@"romaji"];
            aobject.other_titles = @{@"synonyms" : d[@"synonyms"] && d[@"synonyms"] != [NSNull null] ? d[@"synonyms"] : @[] , @"english" : d[@"title"][@"english"] != [NSNull null] && d[@"title"][@"english"] ? @[d[@"title"][@"english"]] : @[], @"japanese" : d[@"title"][@"native"] != [NSNull null] && d[@"title"][@"native"] ? @[d[@"title"][@"native"]] : @[] };
            if (d[@"coverImage"] != [NSNull null]) {
                aobject.image_url = d[@"coverImage"] != [NSNull null] ? d[@"coverImage"][@"large"] : @"";
            }
            aobject.status = d[@"status"] != [NSNull null] ? d[@"status"] : @"NOT_YET_RELEASED";
            if ([aobject.status isEqualToString:@"FINISHED"]||[aobject.status isEqualToString:@"CANCELLED"]) {
                aobject.status = @"finished airing";
            }
            else if ([aobject.status isEqualToString:@"RELEASING"]) {
                aobject.status = @"currently airing";
            }
            else if ([aobject.status isEqualToString:@"NOT_YET_RELEASED"]) {
                aobject.status = @"not yet aired";
            }
            aobject.episodes = d[@"episodes"] != [NSNull null] ? ((NSNumber *)d[@"episodes"]).intValue : 0;
            aobject.type = d[@"format"] != [NSNull null] ? [Utility convertAnimeType:d[@"format"]] : @"";
            aobject.synposis = d[@"description"] != [NSNull null] ? [(NSString *)d[@"description"] stripHtml] : @"No synopsis available.";
            
            [aobject parseSeason];
            [tmparray addObject:aobject.NSDictionaryRepresentation];
        }
    }
    return tmparray;
}

#pragma mark helpers

+ (NSString *)convertMangaType:(NSString *)type {
    NSString *tmpstr = type.lowercaseString;
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    tmpstr = tmpstr.capitalizedString;
    return tmpstr;
}

+ (NSString *)convertDate:(NSDictionary *)date {
    NSString *tmpyear = ((NSNumber *)date[@"year"]).stringValue;
    NSString *tmpmonth = ((NSNumber *)date[@"month"]).stringValue;
    NSString *tmpday = ((NSNumber *)date[@"day"]).stringValue;
    if (tmpmonth.intValue < 10) {
        tmpmonth = [@"0" stringByAppendingString:tmpmonth];
    }
    if (tmpday.intValue < 10) {
        tmpday = [@"0" stringByAppendingString:tmpday];
    }
    return [NSString stringWithFormat:@"%@-%@-%@", tmpyear, tmpmonth, tmpday];
}
@end
