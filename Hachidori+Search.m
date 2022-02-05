//
//  Hachidori+Search.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//
//

#import "Hachidori+Search.h"
#import "Hachidori+AnimeRelations.h"
#import "AtarashiiAPIListFormatKitsu.h"
#import "AtarashiiAPIListFormatAniList.h"
#import "AtarashiiAPIListFormatMAL.h"
#import "Utility.h"
#import <AFNetworking/AFNetworking.h>
#import "ExceptionsCache.h"
#import <DetectionKit/Recognition.h>
#include <math.h>

@implementation Hachidori (Search)
- (NSString *)searchanime {
    // Searches for ID of associated title
    NSString * searchtitle = self.detectedscrobble.DetectedTitle;
    if (self.detectedscrobble.DetectedSeason > 1) {
        // Specifically search for season
        for (int i = 0; i < 2; i++) {
            NSString * tmpid;
            switch (i) {
                case 0:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i", [Utility desensitizeSeason:searchtitle], self.detectedscrobble.DetectedSeason]];
                    break;
                case 1:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %@ Season", [Utility desensitizeSeason:searchtitle], [Utility numbertoordinal:self.detectedscrobble.DetectedSeason]]];
                default:
                    break;
            }
            if (tmpid.length > 0) {
                return tmpid;
            }
        }
    }
    else {
        return [self performSearch:searchtitle]; //Perform Regular Search
    }
    return [self performSearch:searchtitle];
}
- (NSString *)performSearch:(NSString *)searchtitle {
    // Begin Search
    NSLog(@"Searching For Title");
    // Set Season for Search Term if any detected.
    //Escape Search Term
    NSString * searchterm = [Utility urlEncodeString:searchtitle];
    if (!searchterm) {
        // Null search term, error out
        NSLog(@"Invalid Search Term");
        return @"";
    }
    // Set up Request
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject;
    switch ([Hachidori currentService]) {
        case 0:
            responseObject = [self.syncmanager syncGET:[NSString stringWithFormat:@"https://kitsu.io/api/edge/anime?filter[text]=%@", searchterm] parameters:nil headers:@{} task:&task error:&error];
            if (responseObject) {
                responseObject = [AtarashiiAPIListFormatKitsu KitsuAnimeSearchtoAtarashii:responseObject];
            }
            break;
        case 1:
            responseObject = [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilisttitlesearch, @"variables" : @{@"query" : [self cleanupsearchterm:searchtitle], @"type" : @"ANIME"}} headers:@{} task:&task error:&error];
            if (responseObject) {
                responseObject = [AtarashiiAPIListFormatAniList AniListAnimeSearchtoAtarashii:responseObject];
            }
            break;
        case 2:
            responseObject = [self.syncmanager syncGET:@"https://api.myanimelist.net/v2/anime" parameters:@{@"q" : searchtitle.length > 50 ? [searchtitle substringToIndex:50] : searchtitle, @"limit" : @(25), @"fields" : @"num_episodes,status,media_type,nsfw,alternative_titles"} headers:@{} task:&task error:&error];
            if (responseObject) {
                responseObject = [AtarashiiAPIListFormatMAL MALAnimeSearchtoAtarashii:responseObject];
            }
            break;
        default:
            self.Success = NO;
            return @"";
    }
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    switch (statusCode) {
        case 0:
            self.Success = NO;
            return @"";
        case 200:
            return [self findaniid:responseObject searchterm:searchtitle];
        default:
            self.Success = NO;
            return @"";
    }
    
}
- (NSString *)findaniid:(id)responseObject searchterm:(NSString *) term {
    //Initalize NSString to dump the title temporarily
    NSString *theshowtitle = @"";
    NSString *alttitle = @"";
    // Remove Colons
    term = [term stringByReplacingOccurrencesOfString:@":" withString:@""];
    //Create Regular Expression
    OnigRegexp   *regex;
    //Retrieve the ID. Note that the most matched title will be on the top
    // For Sanity (TV shows and OVAs usually have more than one episode)
    self.detectedscrobble.DetectedTitleisMovie = [self.detectedscrobble.DetectedType isEqualToString:@"Movie"] || [self.detectedscrobble.DetectedType isEqualToString:@"movie"] || self.detectedscrobble.DetectedEpisode.length == 0;
    NSLog(@"%@", self.detectedscrobble.DetectedTitleisMovie ? @"Title is a movie" : @"Title is not a movie.");
    // Populate Sorted Array
    NSArray * sortedArray = [self filterArray:responseObject];
    // Used for String Comparison
    NSDictionary * titlematch1;
    NSDictionary * titlematch2;
    int mstatus = 0;
    // Search
    for (int i = 0; i < 3; i++) {
        switch (i) {
            case 1:
                regex = [OnigRegexp compile:[NSString stringWithFormat:@"(%@)",term] options:OnigOptionIgnorecase];
                break;
            case 2:
                regex = [OnigRegexp compile:[[NSString stringWithFormat:@"(%@)",term] stringByReplacingOccurrencesOfString:@" " withString:@"|"] options:OnigOptionIgnorecase];
                break;
            default:
                break;
        }
        
        // Check TV, ONA, Special, OVA, Other
        for (NSDictionary *searchentry in sortedArray) {
            // Populate titles
            theshowtitle = [NSString stringWithFormat:@"%@",searchentry[@"title"]];
            alttitle = ((NSArray *)searchentry[@"other_titles"][@"english"]).count > 0 ? searchentry[@"other_titles"][@"english"][0] : ((NSArray *)searchentry[@"other_titles"][@"japanese"]).count ? searchentry[@"other_titles"][@"japanese"][0] : @"";
            int matchstatus = 0;
            if (self.detectedscrobble.corrected) {
                // Exact match only
                if ([theshowtitle isEqualToString:self.detectedscrobble.DetectedTitle]) {
                    matchstatus = PrimaryTitleMatch;
                }
                else {
                    continue;
                }
            }
            else {
                // Remove colons as they are invalid characters for filenames and to improve accuracy
                theshowtitle = [theshowtitle stringByReplacingOccurrencesOfString:@":" withString:@""];
                alttitle = [alttitle stringByReplacingOccurrencesOfString:@":" withString:@""];
                // Perform Recognition
                matchstatus = i > 0 ? [Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i] : [term caseInsensitiveCompare:theshowtitle] == NSOrderedSame ? PrimaryTitleMatch : [term caseInsensitiveCompare:alttitle] == NSOrderedSame ? AlternateTitleMatch : NoMatch;
                if (matchstatus == PrimaryTitleMatch || matchstatus == AlternateTitleMatch) {
                        if (self.detectedscrobble.DetectedTitleisMovie) {
                            self.detectedscrobble.DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
                            if ([[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"Special"]) {
                                self.detectedscrobble.DetectedTitleisMovie = false;
                            }
                        }
                        else {
                            if ([[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"TV"]||[[NSString stringWithFormat:@"%@", searchentry[@"type"]] isEqualToString:@"ONA"]) { // Check Seasons if the title is a TV show type
                                // Used for Season Checking
                                if (self.detectedscrobble.DetectedSeason != ((NSNumber *)searchentry[@"parsed_season"]).intValue && self.detectedscrobble.DetectedSeason >= 2) { // Season detected, check to see if there is a match. If not, continue.
                                    continue;
                                }
                            }
                        }
                }
                else if (matchstatus == NoMatch) {
                    continue;
                }
                //Return titleid if episode is valid
                int episodes = !searchentry[@"episodes"] ? 0 : ((NSNumber *)searchentry[@"episodes"]).intValue;
                if (episodes == 0 || ((episodes >= self.detectedscrobble.DetectedEpisode.intValue) && self.detectedscrobble.DetectedEpisode.intValue > 0)) {
                    if (((NSNumber *)searchentry[@"parsed_season"]).intValue >= 2 && ((NSNumber *)searchentry[@"parsed_season"]).intValue != self.detectedscrobble.DetectedSeason && (![self.detectedscrobble.DetectedTitle isEqualToString:theshowtitle])) {
                        continue;
                    }
                    NSLog(@"Valid Episode Count");
                    if (sortedArray.count == 1 || self.detectedscrobble.DetectedSeason >= 2) {
                        // Only Result, return
                        return [self foundtitle:((NSNumber *)searchentry[@"id"]).stringValue info:searchentry];
                    }
                    else if (episodes >= self.detectedscrobble.DetectedEpisode.intValue && !titlematch1 && sortedArray.count > 1 && ((term.length < theshowtitle.length+1)||(term.length< alttitle.length+1 && alttitle.length > 0 && matchstatus == AlternateTitleMatch))) {
                        mstatus = matchstatus;
                        titlematch1 = searchentry;
                        continue;
                    }
                    else if (titlematch1 && (episodes >= self.detectedscrobble.DetectedEpisode.intValue || episodes == 0)) {
                        titlematch2 = searchentry;
                        return titlematch1 != titlematch2 ? [self comparetitle:term match1:titlematch1 match2:titlematch2 mstatus:mstatus mstatus2:matchstatus] : [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"id"]] info:searchentry];
                    }
                    else {
                        if ([NSUserDefaults.standardUserDefaults boolForKey:@"UseAnimeRelations"]) {
                            int newid = [self checkAnimeRelations:((NSNumber *)searchentry[@"id"]).intValue];
                            if (newid > 0) {
                                [self foundtitle:((NSNumber *)searchentry[@"id"]).stringValue info:searchentry];
                                return @(newid).stringValue;
                            }
                        }
                        // Only Result, return
                        return [self foundtitle:((NSNumber *)searchentry[@"id"]).stringValue info:searchentry];
                    }
                }
                else if ((episodes < self.detectedscrobble.DetectedEpisode.intValue) && self.detectedscrobble.DetectedEpisode.intValue > 0) {
                    // Check Relations
                    if ([NSUserDefaults.standardUserDefaults boolForKey:@"UseAnimeRelations"]) {
                        int newid = [self checkAnimeRelations:((NSNumber *)searchentry[@"id"]).intValue];
                        if (newid > 0) {
                            [self foundtitle:((NSNumber *)searchentry[@"id"]).stringValue info:searchentry];
                            return @(newid).stringValue;
                        }
                        else {
                            if ([self checkAnimeRelationsForExisting:((NSNumber *)searchentry[@"id"]).intValue]) {
                                [self foundtitle:((NSNumber *)searchentry[@"id"]).stringValue info:searchentry];
                                return @(newid).stringValue;
                            }
                            else {
                                continue;
                            }
                        }
                    }
                }
                else {
                    // Detected episodes exceed total episodes
                    continue;
                }
                
            }
        }
    }
    // If one match is found and not null, then return the id.
    return titlematch1 ? [self foundtitle:[NSString stringWithFormat:@"%@",titlematch1[@"id"]] info:titlematch1] : @"";
    // Nothing found, return empty string
    return @"";
}
- (NSArray *)filterArray:(NSArray *)searchdata {
    NSMutableArray * sortedArray;
    // Filter array based on if the title is a movie or if there is a season detected
    if (self.detectedscrobble.DetectedTitleisMovie) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)" , @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
    }
    else if (self.detectedscrobble.DetectedTitleisEpisodeZero) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(title CONTAINS %@) AND (type ==[c] %@)" , @"Episode 0", @"TV"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"ONA"]]];
    }
    else {
        if (self.detectedscrobble.DetectedType.length > 0) {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type ==[c] %@)", self.detectedscrobble.DetectedType]]];
        }
        else {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV"]]];
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"TV Short"]]];
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"ONA"]]];
            if (self.detectedscrobble.DetectedSeason == 1 | self.detectedscrobble.DetectedSeason == 0) {
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"Special"]]];
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)", @"OVA"]]];
            }
        }
    }
    return sortedArray;
}
- (NSString *)comparetitle:(NSString *)title match1:(NSDictionary *)match1 match2:(NSDictionary *)match2 mstatus:(int)a mstatus2:(int)b {
    // Perform string score between two titles to see if one is the correct match or not
    float score1, score2, ascore1, ascore2;
    double fuzziness = 0.3;
    int season1 = ((NSNumber *)[[Recognition alloc] recognize:match1[@"title"]][@"season"]).intValue;
    int season2 = ((NSNumber *)[[Recognition alloc] recognize:match2[@"title"]][@"season"]).intValue;
    //Score first title
    score1 = string_fuzzy_score([NSString stringWithFormat:@"%@",match1[@"title"]].UTF8String, title.UTF8String, fuzziness);
    ascore1 = string_fuzzy_score([NSString stringWithFormat:@"%@", ((NSArray *)match1[@"other_titles"][@"english"]).count > 0 ? match1[@"other_titles"][@"english"][0] : ((NSArray *)match1[@"other_titles"][@"japanese"]).count ? match1[@"other_titles"][@"japanese"][0] : @""].UTF8String, title.UTF8String, fuzziness);
    // Check for NaN. If Nan, use a negative number
    ascore1 = isnan(ascore1) ? -1 : ascore1;
    NSLog(@"match 1: %@ - %f alt: %f", match1[@"title"], score1, ascore1 );
    //Score Second Title
    score2 = string_fuzzy_score([NSString stringWithFormat:@"%@",match2[@"title"]].UTF8String, title.UTF8String, fuzziness);
    ascore2 = string_fuzzy_score([NSString stringWithFormat:@"%@", ((NSArray *)match2[@"other_titles"][@"english"]).count > 0 ? match2[@"other_titles"][@"english"][0] : ((NSArray *)match2[@"other_titles"][@"japanese"]).count ? match2[@"other_titles"][@"japanese"][0] : @""].UTF8String, title.UTF8String, fuzziness);
    // Check for NaN. If Nan, use a negative number
    ascore2 = isnan(ascore2) ? -1 : ascore2;
    NSLog(@"match 2: %@ - %f alt: %f", match2[@"title"], score2, ascore2 );
    //First Season Score Bonus
    if (self.detectedscrobble.DetectedSeason == 0 || self.detectedscrobble.DetectedSeason == 1) {
        if ([(NSString *)match1[@"title"] rangeOfString:@"First"].location != NSNotFound || [(NSString *)match1[@"title"] rangeOfString:@"1st"].location != NSNotFound) {
            score1 = score1 + .25;
            ascore1 = ascore1 + .25;
        }
        else if ([(NSString *)match2[@"title"] rangeOfString:@"First"].location != NSNotFound || [(NSString *)match2[@"title"] rangeOfString:@"1st"].location != NSNotFound) {
            score2 = score2 + .25;
            ascore2 = ascore2 + .25;
        }
    }
    //Season Scoring Calculation
    if (season1 != self.detectedscrobble.DetectedSeason) {
        ascore1 = ascore1 - .5;
        score1 = score1 - .5;
    }
    if (season2 != self.detectedscrobble.DetectedSeason) {
        ascore2 = ascore2 - .5;
        score2 = score2 - .5;
    }
    
    // Take the highest of both matches scores
    float finalscore1 = score1 > ascore1 ? score1 : ascore1;
    float finalscore2 = score2 > ascore2 ? score2 : ascore2;
    // Compare Scores
    if (finalscore1 == finalscore2 || finalscore1 == INFINITY) {
        //Scores can't be reliably compared, just return the first match
        return [self foundtitle:[NSString stringWithFormat:@"%@",match1[@"id"]] info:match1];
    }
    else if(finalscore1 > finalscore2)
    {
        //Return first title as it has a higher score
        return [self foundtitle:[NSString stringWithFormat:@"%@",match1[@"id"]] info:match1];
    }
    else {
        // Return second title since it has a higher score
        return [self foundtitle:[NSString stringWithFormat:@"%@",match2[@"id"]] info:match2];
    }
}
- (NSString *)foundtitle:(NSString *)titleid info:(NSDictionary *)found {
    //Check to see if Seach Cache is enabled. If so, add it to the cache.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"] && titleid.length > 0 && !self.unittesting) {
        NSNumber * totalepisodes;
        totalepisodes = found[@"episodes"] ? (NSNumber *)found[@"episodes"] : @(0);
        //Save AniID
        [ExceptionsCache addtoCache:self.detectedscrobble.DetectedTitle showid:titleid actualtitle:(NSString *)found[@"title"] totalepisodes: totalepisodes.intValue detectedSeason:self.detectedscrobble.DetectedSeason withService:(int)[Hachidori currentService]];
    }
    //Return the AniID
    return titleid;
}
- (NSString *)cleanupsearchterm:(NSString *)term {
    NSString *tmpterm = [term stringByReplacingOccurrencesOfString:@"?" withString:@""];
    return tmpterm;
}
@end
