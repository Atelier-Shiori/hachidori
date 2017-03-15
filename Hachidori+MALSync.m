//
//  Hachidori+MALSync.m
//  Hachidori
//
//  Created by アナスタシア on 2016/04/17.
//  Copyright 2009-2016 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+MALSync.h"
#import "Hachidori+Keychain.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>

@implementation Hachidori (MALSync)
-(BOOL)sync{
    NSLog(@"Starting MyAnimeList Sync...");
    MALApiUrl = [[NSUserDefaults standardUserDefaults] valueForKey:@"MALAPIURL"];
    int syncstatus = [self checkStatus];
    if (syncstatus == 1) {
        NSLog(@"Adding %@ to user's MyAnimeList library.",LastScrobbledActualTitle);
        return [self addtitle];
    }
    if (syncstatus == 2) {
        NSLog(@"Updating status of %@ in user's MyAnimeList library.",LastScrobbledActualTitle);
        return [self updatetitle];
    }
    else{
        NSLog(@"Sync Failed!");
        return NO;
    }
}
-(int)checkStatus{
    MALID = [self getMALID];
    NSLog(@"Checking Status on MyAnimeList");
    //Set Search API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1/anime/%@?mine=1",MALApiUrl, MALID]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    [request addHeader:[NSString stringWithFormat:@"Basic %@",[self getBase64]]  forKey:@"Authorization"];
    //Perform Search
    [request startRequest];
    // Get Status Code
    long statusCode = [request getStatusCode];
    NSError * error = [request getError]; // Error Detection
    if (statusCode == 200 ) {
        NSError* jerror;
        NSDictionary *animeinfo = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:NSJSONReadingMutableContainers error:&jerror];
        // Check if title needs to be added or not.
        if (animeinfo[@"watched_status"] == [NSNull null]) {
            NSLog(@"Not on MAL List");
            return 1;
        }
        else {
            NSLog(@"Title on MAL List");
            return 2;
        }
    }
    else if (error !=nil){
        NSLog(@"MAL Sync Failed, incorrect credentials or connectivity error.");
        return 0;
    }
    else {
         NSLog(@"MAL Sync Failed, unknown error.");
        return 0;
    }
    //Should never happen, but...
    return 0;

}
-(BOOL)updatetitle{
    // Update the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1/animelist/anime/%@", MALApiUrl, MALID]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    [request addHeader:[NSString stringWithFormat:@"Basic %@",[self getBase64]]  forKey:@"Authorization"];
    [request setPostMethod:@"PUT"];
    // Set info
    [request addFormData:LastScrobbledEpisode forKey:@"episodes"];
    //Rewatch Status
    if (rewatching) {
            [request addFormData:@"1" forKey:@"is_rewatching"];
    }
    else{
            [request addFormData:@"0" forKey:@"is_rewatching"];
    }
    [request addFormData:@(rewatchcount).stringValue forKey:@"rewatch_count"];
    
    [request addFormData:TitleNotes forKey:@"comments"];
    
    //Set Status
    if ([WatchStatus isEqual:@"current"]) {
        [request addFormData:@"watching" forKey:@"status"];
    }
    else {
        [request addFormData:WatchStatus forKey:@"status"];
    }
    
    
    // Set existing score to prevent the score from being erased.
    int tmpscore = (int)TitleScore;
    [request addFormData:@(tmpscore*2).stringValue forKey:@"score"];
    // Do Update
    [request startFormRequest];
    
    switch ([request getStatusCode]) {
        case 200:
            // Update Successful
            NSLog(@"MAL Sync OK.");
            return YES;
        default:
            // Update Unsuccessful
            NSLog(@"MAL Sync Failed.");
            return NO;
    }
}
-(BOOL)addtitle{
    // Add the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/2/animelist/anime", MALApiUrl]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    [request addHeader:[NSString stringWithFormat:@"Basic %@",[self getBase64]]  forKey:@"Authorization"];
    [request addFormData:MALID forKey:@"anime_id"];
    [request addFormData:LastScrobbledEpisode forKey:@"episodes"];
    
    // Check if the detected episode is equal to total episodes. If so, set it as complete (mostly for specials and movies)
    //Set Status
    if ([WatchStatus isEqual:@"current"]) {
        [request addFormData:@"watching" forKey:@"status"];
    }
    else {
        [request addFormData:WatchStatus forKey:@"status"];
    }
    // Do Update
    [request startFormRequest];
    
    
    //Set Title State for Title
    WatchStatus = @"watching";
    switch ([request getStatusCode]) {
        case 200:
        case 201:
            NSLog(@"MAL Sync OK.");
            return YES;
        default:
            // Update Unsuccessful
            NSLog(@"MAL Sync Failed.");
            return NO;
    }

}
-(NSString *)getMALID{
    NSLog(@"Retrieving MyAnimeList Anime ID from Kitsu...");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/anime/%@/mappings", AniID]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Get Information
    [request startRequest];
    // Get Status Code
    long statusCode = [request getStatusCode];
    if (statusCode == 200) {
        NSError* error;
        NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&error];
        NSArray * mappings = d[@"data"];
        for (NSDictionary * m in mappings){
            if ([[NSString stringWithFormat:@"%@",[m[@"attributes"] valueForKey:@"externalSite"]] isEqualToString:@"myanimelist/anime"]){
                return [NSString stringWithFormat:@"%@",[m[@"attributes"] valueForKey:@"externalId"]];
            }
        }
    }
    
    return @"";
}
@end
