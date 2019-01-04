//
//  AtarashiiAPIListFormatKitsu.m
//  Shukofukurou
//
//  Created by 桐間紗路 on 2017/12/18.
//  Copyright © 2017年 MAL Updater OS X Group. All rights reserved.
//

#import "AtarashiiAPIListFormatKitsu.h"
#import "AtarashiiDataObjects.h"
#import "Utility.h"

@implementation AtarashiiAPIListFormatKitsu
+ (NSDictionary *)KitsuAnimeListEntrytoAtarashii:(id)data {
    if (((NSArray *)data[@"data"]).count > 0) {
        AtarashiiAnimeListObject *lentry = [AtarashiiAnimeListObject new];
        NSDictionary *entry = data[@"data"][0];
        lentry.entryid = ((NSNumber *)entry[@"id"]).intValue;
        if ([(NSString *)entry[@"attributes"][@"status"] isEqualToString:@"on_hold"]) {
            lentry.watched_status = @"on-hold";
        }
        else if ([(NSString *)entry[@"attributes"][@"status"] isEqualToString:@"planned"]) {
            lentry.watched_status = @"plan to watch";
        }
        else if ([(NSString *)entry[@"attributes"][@"status"] isEqualToString:@"current"]) {
            lentry.watched_status = @"watching";
        }
        else {
            lentry.watched_status = (NSString *)entry[@"attributes"][@"status"];
        }
        lentry.watched_episodes = ((NSNumber *)entry[@"attributes"][@"progress"]).intValue;
        if (entry[@"attributes"][@"ratingTwenty"] != [NSNull null]) {
            lentry.score = ((NSNumber *)entry[@"attributes"][@"ratingTwenty"]).intValue;
        }
        lentry.watching_start = entry[@"attributes"][@"startedAt"] != [NSNull null] ? [(NSString *)entry[@"attributes"][@"startedAt"] substringToIndex:10] : @"";
        lentry.watching_end  = entry[@"attributes"][@"finishedAt"] != [NSNull null] ? [(NSString *)entry[@"attributes"][@"finishedAt"] substringToIndex:10] : @"";
        lentry.rewatching = ((NSNumber *)entry[@"attributes"][@"reconsuming"]).boolValue;
        lentry.rewatch_count = ((NSNumber *)entry[@"attributes"][@"reconsumeCount"]).intValue;
        lentry.personal_comments = entry[@"attributes"][@"notes"];
        lentry.private_entry = ((NSNumber *) entry[@"attributes"][@"private"]).boolValue;
    return lentry.NSDictionaryRepresentation.copy;
    }
    return nil;
}
+ (NSDictionary *)KitsuAnimeInfotoAtarashii:(NSDictionary *)data {
    AtarashiiAnimeObject *aobject = [AtarashiiAnimeObject new];
    NSDictionary *title = data[@"data"];
    NSDictionary *attributes = title[@"attributes"];
    aobject.titleid = ((NSNumber *)title[@"id"]).intValue;
    aobject.title = attributes[@"canonicalTitle"];
    // Create other titles
    aobject.other_titles = @{@"synonyms" : (attributes[@"abbreviatedTitles"] && attributes[@"abbreviatedTitles"]  != [NSNull null]) ? attributes[@"abbreviatedTitles"] : @[], @"english" : attributes[@"titles"][@"en"] && attributes[@"titles"][@"en"] != [NSNull null] ? @[attributes[@"titles"][@"en"]] : attributes[@"titles"][@"en_jp"] && attributes[@"titles"][@"en_jp"] != [NSNull null] ? @[attributes[@"titles"][@"en_jp"]] : @[], @"japanese" : attributes[@"titles"][@"ja_jp"] && attributes[@"titles"][@"ja_jp"] != [NSNull null] ?  @[attributes[@"titles"][@"ja_jp"]] : @[] };
    aobject.rank = attributes[@"ratingRank"] != [NSNull null] ? ((NSNumber *)attributes[@"ratingRank"]).intValue : 0;
    aobject.popularity_rank = attributes[@"popularityRank"] != [NSNull null] ? ((NSNumber *)attributes[@"popularityRank"]).intValue : 0;
    if (attributes[@"posterImage"] != [NSNull null]) {
        aobject.image_url = attributes[@"posterImage"][@"large"] && attributes[@"posterimage"][@"large"] != [NSNull null] ? attributes[@"posterImage"][@"large"] : @"";
    }
    aobject.type = [Utility convertAnimeType:attributes[@"subtype"]];
    aobject.episodes = attributes[@"episodeCount"] != [NSNull null] ? ((NSNumber *)attributes[@"episodeCount"]).intValue : 0;
    aobject.start_date = attributes[@"startDate"];
    aobject.end_date = attributes[@"endDate"];
    aobject.duration = attributes[@"episodeLength"] != [NSNull null] ? ((NSNumber *)attributes[@"episodeLength"]).intValue : 0;
    aobject.classification = attributes[@"ageRating"] != [NSNull null] ? [NSString stringWithFormat:@"%@ - %@", attributes[@"ageRating"], attributes[@"ageRatingGuide"]] : @"Unknown";
    aobject.synposis = attributes[@"synopsis"];
    aobject.members_score = attributes[@"averageRating"] != [NSNull null] ? ((NSNumber *)attributes[@"averageRating"]).floatValue : 0;
    aobject.members_count = attributes[@"userCount"] != [NSNull null] ? ((NSNumber *)attributes[@"userCount"]).intValue : 0;
    aobject.favorited_count = attributes[@"favoritesCount"] != [NSNull null] ? ((NSNumber *)attributes[@"favoritesCount"]).intValue : 0;
    NSString *tmpstatus = attributes[@"status"];
    if ([tmpstatus isEqualToString:@"finished"]) {
        aobject.status = @"finished airing";
    }
    else if ([tmpstatus isEqualToString:@"current"]) {
        aobject.status = @"currently airing";
    }
    else if ([tmpstatus isEqualToString:@"tba"]||[tmpstatus isEqualToString:@"unreleased"]||[tmpstatus isEqualToString:@"upcoming"]) {
        aobject.status = @"not yet aired";
    }
    NSArray * included = data[@"included"];
    NSMutableArray *categories = [NSMutableArray new];
    for (NSDictionary *d in [included filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", @"categories"]]) {
        [categories addObject:d[@"attributes"][@"title"]];
    }
    aobject.genres = categories;
    NSMutableArray *producers = [NSMutableArray new];
    for (NSDictionary *d in [included filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", @"producers"]]) {
        [producers addObject:d[@"attributes"][@"name"]];
    }
    aobject.producers = producers;
    NSMutableDictionary *mappings = [NSMutableDictionary new];
    for (NSDictionary *d in [included filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", @"mappings"]]) {
        mappings[d[@"attributes"][@"externalSite"]] = d[@"attributes"][@"externalId"];
    }
    aobject.mappings = mappings;

    return aobject.NSDictionaryRepresentation;
}

+ (NSArray *)KitsuAnimeSearchtoAtarashii:(NSDictionary *)data {
    NSArray *dataarray = data[@"data"];
    NSMutableArray *tmparray = [NSMutableArray new];
        for (NSDictionary *d in dataarray) {
            @autoreleasepool {
            AtarashiiAnimeObject *aobject = [AtarashiiAnimeObject new];
            aobject.titleid = ((NSNumber *)d[@"id"]).intValue;
            aobject.title = d[@"attributes"][@"canonicalTitle"];
            aobject.other_titles =  @{@"synonyms" : (d[@"attributes"][@"abbreviatedTitles"] && d[@"attributes"][@"abbreviatedTitles"]  != [NSNull null]) ? d[@"attributes"][@"abbreviatedTitles"] : @[], @"english" : d[@"attributes"][@"titles"][@"en"] && d[@"attributes"][@"titles"][@"en"] != [NSNull null] ? @[d[@"attributes"][@"titles"][@"en"]] : d[@"attributes"][@"titles"][@"en_jp"] && d[@"attributes"][@"titles"][@"en_jp"] != [NSNull null] ? @[d[@"attributes"][@"titles"][@"en_jp"]] : @[], @"japanese" : d[@"attributes"][@"titles"][@"ja_jp"] && d[@"attributes"][@"titles"][@"ja_jp"] != [NSNull null] ?  @[d[@"attributes"][@"titles"][@"ja_jp"]] : @[] };
            aobject.episodes = d[@"attributes"][@"episodeCount"] != [NSNull null] ? ((NSNumber *)d[@"attributes"][@"episodeCount"]).intValue : 0;
            aobject.type = [Utility convertAnimeType:d[@"attributes"][@"subtype"]];
            if (d[@"attributes"][@"posterImage"] != [NSNull null]) {
                aobject.image_url = d[@"attributes"][@"posterImage"][@"medium"] && d[@"attributes"][@"posterImage"][@"medium"] != [NSNull null] ? d[@"attributes"][@"posterImage"][@"medium"] : @"";
            }
            aobject.synposis = d[@"attributes"][@"synopsis"] != [NSNull null] ? d[@"attributes"][@"synopsis"] : @"";
            NSString *tmpstatus = d[@"attributes"][@"status"];
            if ([tmpstatus isEqualToString:@"finished"]) {
                aobject.status = @"finished airing";
            }
            else if ([tmpstatus isEqualToString:@"current"]) {
                aobject.status = @"currently airing";
            }
            else if ([tmpstatus isEqualToString:@"tba"]||[tmpstatus isEqualToString:@"unreleased"]||[tmpstatus isEqualToString:@"upcoming"]) {
                aobject.status = @"not yet aired";
            }
                
            [aobject parseSeason];
            [tmparray addObject:aobject.NSDictionaryRepresentation];
        }
    }
    return tmparray;
}

@end
