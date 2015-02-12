//
//  Hachidori+Search.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//
//

#import "Hachidori+Search.h"
#import "Utility.h"
#import "EasyNSURLConnection.h"
#import "ExceptionsCache.h"

@implementation Hachidori (Search)
-(NSString *)searchanime{
    // Searches for ID of associated title
    NSString * searchtitle = DetectedTitle;
    if (DetectedSeason > 1) {
        // Specifically search for season
        for (int i = 0; i < 2; i++) {
            NSString * tmpid;
            switch (i) {
                case 0:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i", [Utility desensitizeSeason:searchtitle], DetectedSeason]];
                    break;
                case 1:
                    tmpid = [self performSearch:[NSString stringWithFormat:@"%@ %i season", [Utility desensitizeSeason:searchtitle], DetectedSeason]];
                default:
                    break;
            }
            if (tmpid.length > 0) {
                return tmpid;
            }
        }
    }
    else{
        return [self performSearch:searchtitle]; //Perform Regular Search
    }
    return [self performSearch:searchtitle];
}
-(NSString *)performSearch:(NSString *)searchtitle{
    // Begin Search
    NSLog(@"Searching For Title");
    // Set Season for Search Term if any detected.
    //Escape Search Term
    NSString * searchterm = [Utility urlEncodeString:searchtitle];
    //Set Search API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/search/anime?query=%@", searchterm]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Perform Search
    [request startRequest];
    
    // Get Status Code
    int statusCode = [request getStatusCode];
    switch (statusCode) {
        case 0:
            online = false;
            Success = NO;
            return @"";
        case 200:
            online = true;
            return [self findaniid:[request getResponseData] searchterm:searchtitle];
        default:
            online = true;
            Success = NO;
            return @"";
    }
    
}
-(NSString *)findaniid:(NSData *)ResponseData searchterm:(NSString *) term{
    // Initalize JSON parser
    NSError* error;
    NSArray *searchdata = [NSJSONSerialization JSONObjectWithData:ResponseData options:kNilOptions error:&error];
    //Initalize NSString to dump the title temporarily
    NSString *theshowtitle = @"";
    NSString *alttitle = @"";
    //Create Regular Expression
    OGRegularExpression    *regex;
    //Retrieve the ID. Note that the most matched title will be on the top
    // For Sanity (TV shows and OVAs usually have more than one episode)
    if(DetectedEpisode.length == 0){
        // Title is a movie
        NSLog(@"Title is a movie");
        DetectedTitleisMovie = true;
    }
    else{
        // Is TV Show
        NSLog(@"Title is not a movie.");
        DetectedTitleisMovie = false;
    }
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
                regex = [OGRegularExpression regularExpressionWithString:[NSString stringWithFormat:@"(%@)",term] options:OgreIgnoreCaseOption];
                break;
            case 1:
                regex = [OGRegularExpression regularExpressionWithString:[[NSString stringWithFormat:@"(%@)",term] stringByReplacingOccurrencesOfString:@" " withString:@"|"] options:OgreIgnoreCaseOption];
                break;
            default:
                break;
        }
        
        // Check TV, ONA, Special, OVA, Other
        for (NSDictionary *searchentry in sortedArray) {
            theshowtitle = [NSString stringWithFormat:@"%@",searchentry[@"title"]];
            alttitle = [NSString stringWithFormat:@"%@", searchentry[@"alternate_title"]];
            int matchstatus = [Utility checkMatch:theshowtitle alttitle:alttitle regex:regex option:i];
            if (matchstatus == 1 || matchstatus == 2) {
                if (DetectedTitleisMovie) {
                    DetectedEpisode = @"1"; // Usually, there is one episode in a movie.
                    if ([[NSString stringWithFormat:@"%@", searchentry[@"show_type"]] isEqualToString:@"Special"]) {
                        DetectedTitleisMovie = false;
                    }
                }
                else{
                    if ([[NSString stringWithFormat:@"%@", searchentry[@"show_type"]] isEqualToString:@"TV"]||[[NSString stringWithFormat:@"%@", searchentry[@"show_type"]] isEqualToString:@"ONA"]) { // Check Seasons if the title is a TV show type
                        // Used for Season Checking
                        OGRegularExpression    *regex2 = [OGRegularExpression regularExpressionWithString:[NSString stringWithFormat:@"(%i(st|nd|rd|th) season|\\W%i)", DetectedSeason, DetectedSeason] options:OgreIgnoreCaseOption];
                        OGRegularExpressionMatch * smatch = [regex2 matchInString:[NSString stringWithFormat:@"%@ - %@ - %@", theshowtitle, alttitle, searchentry[@"slug"]]];
                        if (DetectedSeason >= 2) { // Season detected, check to see if there is a matcch. If not, continue.
                            if (smatch == nil) {
                                continue;
                            }
                        }
                        else{
                            if (smatch != nil && DetectedSeason >= 2) { // No Season, check to see if there is a season or not. If so, continue.
                                continue;
                            }
                        }
                    }
                }
                //Return titleid if episode is valid
                int episodecount;
                if (searchentry[@"episode_count"] == [NSNull null]) {
                    // No episode Count, set episode count to zero
                    episodecount = 0;
                }
                else{
                    //Set Episode Count
                    episodecount = [[NSString stringWithFormat:@"%@", searchentry[@"episode_count"]] intValue];
                }
                if (episodecount == 0 || ( episodecount >= [DetectedEpisode intValue])) {
                    NSLog(@"Valid Episode Count");
                    if (sortedArray.count == 1 || DetectedSeason >= 2){
                        // Only Result, return
                        return [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"slug"]] info:searchentry];
                    }
                    else if (titlematch1 == nil && sortedArray.count > 1 && ((term.length + 2 < theshowtitle.length)||(term.length + 2 < alttitle.length && alttitle.length > 0 && matchstatus == 2))){
                        mstatus = matchstatus;
                        titlematch1 = searchentry;
                        continue;
                    }
                    else if (titlematch1 != nil){
                        titlematch2 = searchentry;
                        if (titlematch1 != titlematch2) {
                            return [self comparetitle:term match1:titlematch1 match2:titlematch2 mstatus:mstatus mstatus2:matchstatus];
                        }
                        else{
                            // Only Result, return
                            return [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"slug"]] info:searchentry];
                        }
                    }
                    else{
                        // Only Result, return
                        return [self foundtitle:[NSString stringWithFormat:@"%@",searchentry[@"slug"]] info:searchentry];
                    }
                }
                else{
                    // Detected episodes exceed total episodes
                    continue;
                }
                
            }
        }
    }
    // If one match is found and not null, then return the id.
    if (titlematch1 != nil) {
        // Only Result, return
        return [self foundtitle:[NSString stringWithFormat:@"%@",titlematch1[@"slug"]] info:titlematch1];
    }
    // Nothing found, return empty string
    return @"";
}
-(NSArray *)filterArray:(NSArray *)searchdata{
    NSMutableArray * sortedArray;
    // Filter array based on if the title is a movie or if there is a season detected
    if (DetectedTitleisMovie) {
        sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)" , @"Movie"]]];
        [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"Special"]]];
    }
    else{
        // Check if there is any type keywords. If so, only focus on that show type
        OGRegularExpression * check = [OGRegularExpression regularExpressionWithString:@"(Special|OVA|ONA)" options:OgreIgnoreCaseOption];
        if ([check matchInString:DetectedTitle]) {
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type LIKE %@)", [[check matchInString:DetectedTitle] matchedString]]]];
        }
        else{
            sortedArray = [NSMutableArray arrayWithArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"TV"]]];
            [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"ONA"]]];
            if (DetectedSeason == 1 | DetectedSeason == 0) {
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"Special"]]];
                [sortedArray addObjectsFromArray:[searchdata filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(show_type == %@)", @"OVA"]]];
            }
        }
    }
    return sortedArray;
}
-(NSString *)comparetitle:(NSString *)title match1:(NSDictionary *)match1 match2:(NSDictionary *)match2 mstatus:(int)a mstatus2:(int)b{
    // Perform string score between two titles to see if one is the correct match or not
    float score1, score2, ascore1, ascore2;
    double fuzziness = 0.3;
    //Score first title
    score1 = string_fuzzy_score(title.UTF8String, [[NSString stringWithFormat:@"%@", match1[@"title"]] UTF8String], fuzziness);
    ascore1 = string_fuzzy_score(title.UTF8String, [[NSString stringWithFormat:@"%@", match1[@"alternate_title"]] UTF8String], fuzziness);
    //Score Second Title
    score2 = string_fuzzy_score(title.UTF8String, [[NSString stringWithFormat:@"%@", match2[@"title"]] UTF8String], fuzziness);
    ascore2 = string_fuzzy_score(title.UTF8String, [[NSString stringWithFormat:@"%@", match2[@"alternate_title"]] UTF8String], fuzziness);
    if (score1 == score2 || ascore1 == ascore2 || score1 == INFINITY) {
        //Scores can't be reliably compared, just return the first match
        return [self foundtitle:[NSString stringWithFormat:@"%@",match1[@"slug"]] info:match1];
    }
    else if(a == 2 || b == 2){
        if(ascore1 > ascore2)
        {
            //Return first title as it has a higher score
            return [self foundtitle:[NSString stringWithFormat:@"%@",match1[@"slug"]] info:match1];
        }
        else{
            // Return second title since it has a higher score
            return [self foundtitle:[NSString stringWithFormat:@"%@",match2[@"slug"]] info:match2];
        }
    }
    else if(score1 > score2)
    {
        //Return first title as it has a higher score
        return [self foundtitle:[NSString stringWithFormat:@"%@",match1[@"slug"]] info:match1];
    }
    else{
        // Return second title since it has a higher score
        return [self foundtitle:[NSString stringWithFormat:@"%@",match2[@"slug"]] info:match2];
    }
}
-(NSString *)foundtitle:(NSString *)titleid info:(NSDictionary *)found{
    //Check to see if Seach Cache is enabled. If so, add it to the cache.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useSearchCache"] && titleid.length > 0 && !unittesting) {
        //Save AniID
        [ExceptionsCache addtoCache:DetectedTitle showid:titleid actualtitle:(NSString *)found[@"title"] totalepisodes:[(NSNumber *)found[@"episodes"] intValue] ];
    }
    //Return the AniID
    return titleid;
}
@end
