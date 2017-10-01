//
//  Hachidori+Search.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//
//

#import "Hachidori+Search.h"
#import "Utility.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import "ExceptionsCache.h"
#import <DetectionKit/Recognition.h>

@implementation Hachidori (Search)
- (NSString *)searchanime {
    // Searches for ID of associated title
    NSString * searchtitle = self.DetectedTitle;
    if (self.DetectedSeason > 1) {
        // Specifically search for season
        for (int i = 0; i < 2; i++) {
            NSString * tmpid;
            switch (i) {
                case 0:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i", [Utility desensitizeSeason:searchtitle], self.DetectedSeason]];
                    break;
                case 1:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i season", [Utility desensitizeSeason:searchtitle], self.DetectedSeason]];
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
    //Set Search API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/anime?filter[text]=%@", searchterm]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Perform Search
    [request startRequest];
    
    // Get Status Code
    long statusCode = [request getStatusCode];
    switch (statusCode) {
        case 0:
            self.Success = NO;
            return @"";
        case 200:
            return [self findaniid:[request getResponseData] searchterm:searchtitle];
        default:
            self.Success = NO;
            return @"";
    }
    
}
- (NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *) term {
    // Initalize JSON parser
    NSError* error;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:ResponseData options:kNilOptions error:&error];
    NSArray * tmpa = data[@"data"];
    tmpa = [NSArray arrayWithArray:[tmpa filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(type == %@)" , @"anime"]]];
    NSMutableArray * searchdata = [NSMutableArray new];
    for (NSDictionary * a in tmpa) {
        NSMutableDictionary * tmpd = [NSMutableDictionary new];
        [tmpd addEntriesFromDictionary:a[@"attributes"]];
        tmpd[@"id"] = a[@"id"];
        [searchdata addObject:tmpd];
    }
    tmpa = nil;
    //Initalize NSString to dump the title temporarily
    NSString *theshowtitle = @"";
    NSString *alttitle = @"";
    // Remove Colons
    term = [term stringByReplacingOccurrencesOfString:@":" withString:@""];
    //Create Regular Expression
    OnigRegexp   *regex;
    //Retrieve the ID. Note that the most matched title will be on the top
    // For Sanity (TV shows and OVAs usually have more than one episode)
    self.DetectedTitleisMovie = [self.DetectedType isEqualToString:@"Movie"] || [self.DetectedType isEqualToString:@"movie"];
    NSLog(@"%@", self.DetectedTitleisMovie ? @"Title is a movie" : @"Title is not a movie.");
    // Populate Sorted Array
    NSArray * sortedArray = [self filterArray:searchdata];
    searchdata = nil;
    // Used for String Comparison
    NSDictionary * titlematch1;
    NSDictionary * titlematch2;
    int mstatus = 0;
    // Search
    for (int i = 0; i < 2; i++) {
        switch (i) {
            case 0:
                regex = [OnigRegexp compile:[NSString stringWithFormat:@"(%@)",term] options:OnigOptionIgnorecase];
                break;
            case 1:
                regex = [OnigRegexp compile:[[NSString stringWithFormat:@"(%@)",term] stringByReplacingOccurrencesOfString:@" " withString:@"|"] options:OnigOptionIgnorecase];
                break;
            default:
                break;
        }
        
        // Check TV, ONA, Special, OVA, Other
        for (NSDictionary *searchentry in sortedArray) {
            // Populate titles
            NSDictionary * titles = searchentry[@"titles"];
            theshowtitle = [NSString stringWithFormat:@"%@",titles[@"en_jp"]];
            alttitle = [NSString stringWithFormat:@"%@", titles[@"en"]];
            // Remove colons as they are invalid characters for filenames and to improve accuracy
            theshowtitle = [theshowtitle stringByReplacingOccurrencesOfString:@":" withString:@""];
            alttitle = [alttitle stringByReplacingOccurrencesOfString:@":" withString:@""];
            // Perform Recognition
            int matchstatus = [Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i];
            if (matchstatus == 1 || matchstatus == 2) {
                if (self.DetectedTitleisMovie) {
                    self.DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
                    if ([[NSString stringWithFormat:@"%@", searchentry[@"showType"]] isEqualToString:@"Special"]) {
                        self.DetectedTitleisMovie = false;
                    }
                }
                else {
                    if ([[NSString stringWithFormat:@"%@", searchentry[@"showType"]] isEqualToString:@"TV"]||[[NSString stringWithFormat:@"%@", searchentry[@"showType"]] isEqualToString:@"ONA"]) { // Check Seasons if the title is a TV show type
                        // Used for Season Checking
                        OnigRegexp   *regex2 = [OnigRegexp compile:[NSString stringWithFormat:@"(%i(st|nd|rd|th) season|\\W%i)", self.DetectedSeason, self.DetectedSeason] options:OnigOptionIgnorecase];
                        OnigResult * smatch = [regex2 match:[NSString stringWithFormat:@"%@ - %@ - %@", theshowtitle, alttitle, searchentry[@"slug"]]];
                        if (self.DetectedSeason >= 2) { // Season detected, check to see if there is a matcch. If not, continue.
                            if (!smatch) {
                                continue;
                            }
                        }
                        else {
                            if (smatch && self.DetectedSeason >= 2) { // No Season, check to see if there is a season or not. If so, continue.
                                continue;
                            }
                        }
                    }
                }
                //Return titleid if episode is valid
                int episodecount = !searchentry[@"episodeCount"] ? 0 : [NSString stringWithFormat:@"%@", searchentry[@"episode_count"]].intValue;
                if (episodecount == 0 || ( episodecount >= self.DetectedEpisode.intValue)) {
                    NSLog(@"Valid Episode Count");
                    if (sortedArray.count == 1 || self.DetectedSeason >= 2) {
                        // Only Result, return
                        return [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"id"]] info:searchentry];
                    }
                    else if (!titlematch1 && sortedArray.count > 1 && ((term.length < theshowtitle.length)||(term.length< alttitle.length && alttitle.length > 0 && matchstatus == 2))) {
                        mstatus = matchstatus;
                        titlematch1 = searchentry;
                        continue;
                    }
                    else if (titlematch1) {
                        titlematch2 = searchentry;
                        return titlematch1 != titlematch2 ? [self comparetitle:term match1:titlematch1 match2:titlematch2 mstatus:mstatus mstatus2:matchstatus] : [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"id"]] info:searchentry];
                    }
                    else {
                        // Only Result, return
                        return [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"id"]] info:searchentry];
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
    if (self.DetectedTitleisMovie) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(showType == %@)" , @"movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(showType == %@)", @"special"]]];
    }
    else if (self.DetectedTitleisEpisodeZero) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(canonicalTitle CONTAINS %@) AND (showType ==[c] %@)" , @"Episode 0", @"TV"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(showType == %@)", @"special"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(showType == %@)", @"movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(showType == %@)", @"OVA"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(showType == %@)", @"ONA"]]];
    }
    else {
        if (self.DetectedType.length > 0) {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(showType ==[c] %@)", self.DetectedType]]];
        }
        else {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(showType == %@)", @"TV"]]];
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"ONA"]]];
            if (self.DetectedSeason == 1 | self.DetectedSeason == 0) {
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(showType == %@)", @"special"]]];
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(showType == %@)", @"OVA"]]];
            }
        }
    }
    return sortedArray;
}
- (NSString *)comparetitle:(NSString *)title match1:(NSDictionary *)match1 match2:(NSDictionary *)match2 mstatus:(int)a mstatus2:(int)b {
    // Perform string score between two titles to see if one is the correct match or not
    float score1, score2, ascore1, ascore2;
    double fuzziness = 0.3;
    NSDictionary * mtitle1 = match1[@"titles"];
    NSDictionary * mtitle2 = match2[@"titles"];
    int season1 = ((NSNumber *)[[Recognition alloc] recognize:mtitle1[@"en_jp"]][@"season"]).intValue;
    int season2 = ((NSNumber *)[[Recognition alloc] recognize:mtitle2[@"en_jp"]][@"season"]).intValue;
    //Score first title
    score1 = string_fuzzy_score(title.UTF8String, [NSString stringWithFormat:@"%@",mtitle1[@"en_jp"]].UTF8String, fuzziness);
    ascore1 = string_fuzzy_score(title.UTF8String, [NSString stringWithFormat:@"%@", mtitle1[@"en"]].UTF8String, fuzziness);
    NSLog(@"match 1: %@ - %f alt: %f", mtitle1[@"en_jp"], score1, ascore1 );
    //Score Second Title
    score2 = string_fuzzy_score(title.UTF8String, [NSString stringWithFormat:@"%@", mtitle2[@"en_jp"]].UTF8String, fuzziness);
    ascore2 = string_fuzzy_score(title.UTF8String, [NSString stringWithFormat:@"%@", mtitle2[@"en"]].UTF8String, fuzziness);
    NSLog(@"match 2: %@ - %f alt: %f", mtitle2[@"en_jp"], score2, ascore2 );
    //First Season Score Bonus
    if (self.DetectedSeason == 0 || self.DetectedSeason == 1) {
        if ([(NSString *)mtitle1[@"en_jp"] rangeOfString:@"First"].location != NSNotFound || [(NSString *)mtitle1[@"en_jp"] rangeOfString:@"1st"].location != NSNotFound) {
            score1 = score1 + .25;
            ascore1 = ascore1 + .25;
        }
        else if ([(NSString *)mtitle2[@"en_jp"] rangeOfString:@"First"].location != NSNotFound || [(NSString *)mtitle2[@"en_jp"] rangeOfString:@"1st"].location != NSNotFound) {
            score2 = score2 + .25;
            ascore2 = ascore2 + .25;
        }
    }
    //Season Scoring Calculation
    if (season1 != self.DetectedSeason) {
        ascore1 = ascore1 - .5;
        score1 = score1 - .5;
    }
    if (season2 != self.DetectedSeason) {
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
        totalepisodes = found[@"episode_count"] ? (NSNumber *)found[@"episodeCount"] : @(0);
        //Save AniID
        NSDictionary * title = found[@"titles"];
        [ExceptionsCache addtoCache:self.DetectedTitle showid:titleid actualtitle:(NSString *)title[@"en_jp"] totalepisodes: totalepisodes.intValue];
    }
    //Return the AniID
    return titleid;
}
@end
