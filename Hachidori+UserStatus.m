//
//  Hachidori+UserStatus.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+UserStatus.h"
#import "EasyNSURLConnection.h"
#import "Hachidori+Keychain.h"

@implementation Hachidori (UserStatus)
-(BOOL)checkstatus:(NSString *)titleid {
    NSLog(@"Checking %@", titleid);
    // Update the title
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries?filter[user-id]=%@&filter[media-id]=%@", [self getUserid], titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    // Get Information
    [request startoAuthRequest];
    NSDictionary * d;
    long statusCode = [request getStatusCode];
    NSError * error = [request getError];
    if (statusCode == 200 || statusCode == 201 ) {
        online = true;
        //return Data
        NSError * jerror;
        d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&jerror];
        if (((NSArray *)d[@"data"]).count > 0) {
            d = [NSArray arrayWithArray:d[@"data"]][0];
            EntryID = d[@"id"];
            d = d[@"attributes"];
            NSLog(@"Title on list");
            [self populateStatusData:d id:titleid];
        }
        else{
            NSLog(@"Title not on list");
            EntryID = nil;
            WatchStatus = @"current";
            LastScrobbledInfo = [self retrieveAnimeInfo:AniID];
            DetectedCurrentEpisode = 0;
            TitleScore  = 0;
            isPrivate = [defaults boolForKey:@"setprivate"];
            TitleNotes = @"";
            LastScrobbledTitleNew = true;
            rewatching = false;
            rewatchcount = 0;
            // MAL ID for MAL Syncing
            //MALID = [NSString stringWithFormat:@"%@", LastScrobbledInfo[@"mal_id"]];
        }
        if (LastScrobbledInfo[@"episode_count"] == nil ) { // To prevent the scrobbler from failing because there is no episode total.
            TotalEpisodes = 0; // No Episode Total, Set to 0.
        }
        else { // Episode Total Exists
            TotalEpisodes = ((NSNumber *)LastScrobbledInfo[@"episodeCount"]).intValue;
        }
        // New Update Confirmation
        if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && LastScrobbledTitleNew && !correcting)|| ([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !LastScrobbledTitleNew && !correcting)) {
            // Manually confirm updates
            confirmed = false;
        }
        else{
            // Automatically confirm updates
            confirmed = true;
        }
        return YES;
    }
    else if (error !=nil){
        if (error.code == NSURLErrorNotConnectedToInternet) {
            online = false;
            return NO;
        }
        else {
            // Token generation failed, users credentials incorrect.
            online = true;
            return NO;
        }
    }
    else {
        // Some Error. Abort
        return NO;
    }
    //Should never happen, but...
    return NO;
}
-(NSDictionary *)retrieveAnimeInfo:(NSString *)aid{
    NSLog(@"Getting Additional Info");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/anime/%@", aid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Get Information
    [request startoAuthRequest];
    // Get Status Code
    long statusCode = [request getStatusCode];
    if (statusCode == 200) {
        NSError* error;
        NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&error];
        d = d[@"data"];
        return d[@"attributes"];
    }
    else{
        NSDictionary * d = [[NSDictionary alloc] init];
        return d;
    }
}
-(void)populateStatusData:(NSDictionary *)d id:(NSString *)aid{
    // Retrieve Anime Information
    NSDictionary * tmpinfo = [self retrieveAnimeInfo:aid];
    WatchStatus = d[@"status"];
    //Get Notes;
    if (d[@"notes"] == [NSNull null]) {
        TitleNotes = @"";
    }
    else {
        TitleNotes = d[@"notes"];
    }
    if (d[@"rating"] == [NSNull null]){
        // Score is null, set to 0
        TitleScore = 0;
    }
    else {
        TitleScore = ((NSNumber *)d[@"rating"]).floatValue;
    }
    // Rewatch Information
    rewatching = [d[@"reconsuming"] boolValue];
    rewatchcount = [d[@"reconsumeCount"] longValue];
    // Privacy Settings
    isPrivate = [d[@"private"] boolValue];
    DetectedCurrentEpisode = ((NSNumber *)d[@"progress"]).intValue;
    LastScrobbledInfo = tmpinfo;
    LastScrobbledTitleNew = false;
    if (rewatching) {
        NSLog(@"Title is being rewatched.");
    }
    // MAL ID for MAL Syncing
    //MALID = [NSString stringWithFormat:@"%@", LastScrobbledInfo[@"mal_id"]];
}
@end
