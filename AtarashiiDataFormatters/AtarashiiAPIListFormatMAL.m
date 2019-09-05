//
//  AtarashiiAPIListFormatMAL.m
//  Hakuchou
//
//  Created by 香風智乃 on 8/23/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "AtarashiiAPIListFormatMAL.h"
#import "AtarashiiDataObjects.h"
#import "Utility.h"

@implementation AtarashiiAPIListFormatMAL
+ (NSDictionary *)MALtoAtarashiiAnimeEntry:(id)data {
        AtarashiiAnimeListObject *aentry = [AtarashiiAnimeListObject new];
        aentry.titleid = ((NSNumber *)data[@"id"]).intValue;
        NSString *strType = data[@"media_type"];
        if ([strType isEqualToString:@"tv"]||[strType isEqualToString:@"ova"]||[strType isEqualToString:@"ona"]) {
            strType = [strType uppercaseString];
        }
        else {
            strType = [strType capitalizedString];
        }
        
        // User Entry
        NSDictionary *listStatus = data[@"my_list_status"];
        aentry.watched_status = [(NSString *)listStatus[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        if ([aentry.watched_status isEqualToString:@"on hold"]) {
            aentry.watched_status = @"on-hold";
        }
        aentry.score = ((NSNumber *)listStatus[@"score"]).intValue;
        aentry.watched_episodes = ((NSNumber *)listStatus[@"num_episodes_watched"]).intValue;
        aentry.rewatching = ((NSNumber *)listStatus[@"is_rewatching"]).boolValue;
        aentry.rewatch_count = ((NSNumber *)listStatus[@"num_times_rewatched"]).intValue;
        aentry.watching_start = listStatus[@"start_date"] ? listStatus[@"start_date"] : @"";
        aentry.watching_end = listStatus[@"finish_date"] ? listStatus[@"finish_date"] : @"";
        aentry.personal_comments = listStatus[@"comments"];
        return aentry.NSDictionaryRepresentation;
}

+ (NSDictionary *)MALAnimeInfotoAtarashii:(NSDictionary *)data {
    AtarashiiAnimeObject *aobject = [AtarashiiAnimeObject new];
    aobject.titleid = ((NSNumber *)data[@"id"]).intValue;
    aobject.title = data[@"title"];
    // Create other titles
    aobject.other_titles = @{@"synonyms" : data[@"alternative_titles"][@"synonyms"] && data[@"alternative_titles"][@"synonyms"] != [NSNull null] ? data[@"alternative_titles"][@"synonyms"] : @[]  , @"english" : data[@"alternative_titles"][@"en"] != [NSNull null] && data[@"alternative_titles"][@"en"] && ((NSString *)data[@"alternative_titles"][@"en"]).length > 0 ? @[data[@"alternative_titles"][@"en"]] : @[], @"japanese" : data[@"alternative_titles"][@"ja"] != [NSNull null] && data[@"alternative_titles"][@"ja"] && ((NSString *)data[@"alternative_titles"][@"ja"]).length > 0 ? @[data[@"alternative_titles"][@"ja"]] : @[] };
    aobject.popularity_rank = data[@"popularity"] != [NSNull null] ? ((NSNumber *)data[@"popularity"]).intValue : 0;
    #if defined(AppStore)
    if (data[@"main_picture"] != [NSNull null] && data[@"main_picture"]) {
        aobject.image_url = data[@"main_picture"][@"large"] && data[@"main_picture"] != [NSNull null] && ![(NSString *)data[@"nsfw"] isEqualToString:@"black"] ? data[@"main_picture"][@"large"] : @"";
    }
    aobject.synposis = [(NSString *)data[@"nsfw"] isEqualToString:@"black"] ? data[@"synopsis"] != [NSNull null] ? data[@"synopsis"] : @"No synopsis available" : @"Synopsis not available for adult titles";
    #else
    bool allowed = ([NSUserDefaults.standardUserDefaults boolForKey:@"showadult"] || ![(NSString *)data[@"nsfw"] isEqualToString:@"black"]);
    if (data[@"main_picture"] != [NSNull null]&& data[@"main_picture"]) {
        aobject.image_url = data[@"main_picture"][@"large"] && data[@"main_picture"] != [NSNull null] && data[@"main_picture"][@"large"] && allowed ?  data[@"main_picture"][@"large"] : @"";
    }
    aobject.synposis = allowed ? data[@"synopsis"] != [NSNull null] ? data[@"synopsis"] : @"No synopsis available" : @"Synopsis not available for adult titles";
    #endif
    NSString *strType = data[@"media_type"];
    if ([strType isEqualToString:@"tv"]||[strType isEqualToString:@"ova"]||[strType isEqualToString:@"ona"]) {
        strType = [strType uppercaseString];
    }
    else {
        strType = [strType capitalizedString];
    }
    aobject.type = strType;
    aobject.episodes = data[@"num_episodes"] && data[@"num_episodes"] != [NSNull null] ? ((NSNumber *)data[@"num_episodes"]).intValue : 0;
    aobject.start_date = data[@"start_date"] != [NSNull null] && data[@"start_date"] ? data[@"start_date"] : @"";
    aobject.end_date = data[@"end_date"] != [NSNull null] && data[@"end_date"] ? data[@"end_date"] : @"";
    aobject.duration = data[@"average_episode_duration"] && data[@"average_episode_duration"] != [NSNull null] ? (((NSNumber *)data[@"average_episode_duration"]).intValue/60) : 0;
    aobject.classification = data[@"rating"] && data[@"rating"] != [NSNull null] ? [[(NSString *)data[@"rating"] stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedString] : @"";
    //aobject.hashtag = data[@"hashtag"] != [NSNull null] ? data[@"hashtag"] : @"";
    aobject.members_score = data[@"mean"] != [NSNull null] && data[@"mean"]? ((NSNumber *)data[@"mean"]).floatValue : 0;
    aobject.status = [(NSString *)data[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    NSMutableArray *genres = [NSMutableArray new];
    for (NSDictionary *genre in data[@"genres"]) {
        [genres addObject:genre[@"name"]];
    }
    aobject.genres = genres;
    NSMutableArray *studiosarray = [NSMutableArray new];
    if (data[@"studios"] != [NSNull null]) {
        for (NSDictionary *studio in data[@"studios"]) {
            [studiosarray addObject:studio[@"name"]];
        }
    }
    aobject.producers = studiosarray;
    /*
    NSMutableArray *mangaadaptations = [NSMutableArray new];
    for (NSDictionary *adpt in [(NSArray *)data[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"ADAPTATION"]]) {
        if ([(NSString *)adpt[@"node"][@"type"] isEqualToString:@"MANGA"]) {
            [mangaadaptations addObject: @{@"manga_id": adpt[@"node"][@"id"], @"title" : adpt[@"node"][@"title"][@"romaji"]}];
        }
    }
    NSMutableArray *sidestories = [NSMutableArray new];
    for (NSDictionary *side in [(NSArray *)data[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"SIDE_STORY"]]) {
        if ([(NSString *)side[@"node"][@"type"] isEqualToString:@"ANIME"]) {
            [sidestories addObject: @{@"anime_id": side[@"node"][@"id"], @"title" : side[@"node"][@"title"][@"romaji"]}];
        }
    }
    NSMutableArray *sequels = [NSMutableArray new];
    for (NSDictionary *sequel in [(NSArray *)data[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"SEQUEL"]]) {
        if ([(NSString *)sequel[@"node"][@"type"] isEqualToString:@"ANIME"]) {
            [sequels addObject: @{@"anime_id": sequel[@"node"][@"id"], @"title" : sequel[@"node"][@"title"][@"romaji"]}];
        }
    }
    NSMutableArray *prequels = [NSMutableArray new];
    for (NSDictionary *prequel in [(NSArray *)data[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"PREQUEL"]]) {
        if ([(NSString *)prequel[@"node"][@"type"] isEqualToString:@"ANIME"]) {
            [prequels addObject: @{@"anime_id": prequel[@"node"][@"id"], @"title" : prequel[@"node"][@"title"][@"romaji"]}];
        }
    }
    aobject.manga_adaptations = mangaadaptations;
    aobject.side_stories = sidestories;
    aobject.sequels = sequels;
    aobject.prequels = prequels;
    */
    return aobject.NSDictionaryRepresentation;
}


+ (NSArray *)MALAnimeSearchtoAtarashii:(NSDictionary *)data {
    NSArray *dataarray = data[@"data"];
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSDictionary *d in dataarray) {
        @autoreleasepool {
            NSDictionary *titleData = d[@"node"];
#if defined(AppStore)
            if ([(NSString *)titleData[@"nsfw"] isEqualToString:@"black"]) {
                continue;
            }
#else
            if ([(NSString *)titleData[@"nsfw"] isEqualToString:@"black"] && ![NSUserDefaults.standardUserDefaults boolForKey:@"showadult"]) {
                continue;
            }
#endif
            AtarashiiAnimeObject *aobject = [AtarashiiAnimeObject new];
            aobject.titleid = ((NSNumber *)titleData[@"id"]).intValue;
            aobject.title = titleData[@"title"];
            // Create other titles
            aobject.other_titles = @{@"synonyms" : titleData[@"alternative_titles"][@"synonyms"] && titleData[@"alternative_titles"][@"synonyms"] != [NSNull null] ? titleData[@"alternative_titles"][@"synonyms"] : @[]  , @"english" : titleData[@"alternative_titles"][@"en"] != [NSNull null] && titleData[@"alternative_titles"][@"en"] && ((NSString *)titleData[@"alternative_titles"][@"en"]).length > 0 ? @[titleData[@"alternative_titles"][@"en"]] : @[], @"japanese" : titleData[@"alternative_titles"][@"ja"] != [NSNull null] && titleData[@"alternative_titles"][@"ja"] && ((NSString *)titleData[@"alternative_titles"][@"ja"]).length > 0 ? @[titleData[@"alternative_titles"][@"ja"]] : @[] };
            if (titleData[@"main_picture"] != [NSNull null]) {
                 aobject.image_url = titleData[@"main_picture"][@"large"] && titleData[@"main_picture"] != [NSNull null] && titleData[@"main_picture"][@"large"] ?  titleData[@"main_picture"][@"large"] : @"";
            }
            aobject.status = [(NSString *)titleData[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            aobject.episodes = titleData[@"num_episodes"] != [NSNull null] ? ((NSNumber *)titleData[@"num_episodes"]).intValue : 0;
            NSString *strType = titleData[@"media_type"];
            if ([strType isEqualToString:@"tv"]||[strType isEqualToString:@"ova"]||[strType isEqualToString:@"ona"]) {
                strType = [strType uppercaseString];
            }
            else {
                strType = [strType capitalizedString];
            }
            aobject.type = strType;
            [aobject parseSeason];
            [tmparray addObject:aobject.NSDictionaryRepresentation];
        }
    }
    return tmparray;
}

@end
