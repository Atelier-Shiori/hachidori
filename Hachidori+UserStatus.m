//
//  Hachidori+UserStatus.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+UserStatus.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import "Hachidori+Keychain.h"
#import "Utility.h"

@implementation Hachidori (UserStatus)
- (BOOL)checkstatus:(NSString *)titleid {
    NSLog(@"Checking %@", titleid);
    // Update the title
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries?filter[user-id]=%@&filter[media-id]=%@", [self getUserid], titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set OAuth Token
    [request addHeader:[NSString stringWithFormat:@"Bearer %@", [[self getFirstAccount] accessToken]] forKey:@"Authorization"];
    // Get Information
    [request startRequest];
    NSDictionary * d;
    long statusCode = [request getStatusCode];
    NSError * error = [request getError];
    if (statusCode == 200 || statusCode == 201 ) {
        //return Data
        NSError * jerror;
        d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&jerror];
        if (((NSArray *)d[@"data"]).count > 0) {
            d = [NSArray arrayWithArray:d[@"data"]][0];
            self.EntryID = d[@"id"];
            d = d[@"attributes"];
            NSLog(@"Title on list");
            [self populateStatusData:d id:titleid];
        }
        else {
            NSLog(@"Title not on list");
            self.EntryID = nil;
            self.WatchStatus = @"current";
            self.LastScrobbledInfo = [self retrieveAnimeInfo:self.AniID];
            self.DetectedCurrentEpisode = 0;
            self.TitleScore  = 0;
            self.isPrivate = [defaults boolForKey:@"setprivate"];
            self.TitleNotes = @"";
            self.LastScrobbledTitleNew = true;
            self.rewatching = false;
            self.rewatchcount = 0;
        }
        if (!self.LastScrobbledInfo[@"episode_count"]) { // To prevent the scrobbler from failing because there is no episode total.
            self.TotalEpisodes = 0; // No Episode Total, Set to 0.
        }
        else { // Episode Total Exists
            self.TotalEpisodes = ((NSNumber *)self.LastScrobbledInfo[@"episodeCount"]).intValue;
        }
        // New Update Confirmation
        if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && self.LastScrobbledTitleNew && !self.correcting)|| ([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !self.LastScrobbledTitleNew && !self.correcting)) {
            // Manually confirm updates
            self.confirmed = false;
        }
        else {
            // Automatically confirm updates
            self.confirmed = true;
        }
        return YES;
    }
    else if (error !=nil) {
        if (error.code == NSURLErrorNotConnectedToInternet) {
            return NO;
        }
        else {
            // Token generation failed, users credentials incorrect.
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
- (NSDictionary *)retrieveAnimeInfo:(NSString *)aid{
    NSLog(@"Getting Additional Info");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/anime/%@", aid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    // Set Auth Header
    [request addHeader:[NSString stringWithFormat:@"Bearer %@", [[self getFirstAccount] accessToken]] forKey:@"Authorization"];
    //Get Information
    [request startRequest];
    // Get Status Code
    long statusCode = [request getStatusCode];
    if (statusCode == 200) {
        NSError* error;
        NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&error];
        d = d[@"data"];
        return d[@"attributes"];
    }
    else {
        NSDictionary * d = [[NSDictionary alloc] init];
        return d;
    }
}
- (void)populateStatusData:(NSDictionary *)d id:(NSString *)aid{
    // Retrieve Anime Information
    NSDictionary * tmpinfo = [self retrieveAnimeInfo:aid];
    self.WatchStatus = d[@"status"];
    //Get Notes;
    if (d[@"notes"] == [NSNull null]) {
        self.TitleNotes = @"";
    }
    else {
        self.TitleNotes = d[@"notes"];
    }
    self.ratingtype = [self getUserRatingType];
    if (d[@"ratingTwenty"] != [NSNull null]) {
        // If user is using the new rating system
        self.TitleScore = ((NSNumber *)d[@"ratingTwenty"]).intValue;
    }
    else if (d[@"rating"] != [NSNull null]) {
        // Old rating system
        float tempscore = ((NSNumber *)d[@"rating"]).floatValue;
        if (self.ratingtype == ratingStandard || self.ratingtype == ratingSimple) {
            self.TitleScore = [Utility translatestandardKitsuRatingtoRatingTwenty:tempscore];
        }
        else {
            self.TitleScore = [Utility translateadvancedKitsuRatingtoRatingTwenty:tempscore];
        }
    }
    else {
        // Score is null, set to 0
        self.TitleScore = 0;
    }
    // Rewatch Information
    self.rewatching = [d[@"reconsuming"] boolValue];
    self.rewatchcount = [d[@"reconsumeCount"] longValue];
    // Privacy Settings
    self.isPrivate = [d[@"private"] boolValue];
    self.DetectedCurrentEpisode = ((NSNumber *)d[@"progress"]).intValue;
    self.LastScrobbledInfo = tmpinfo;
    self.LastScrobbledTitleNew = false;
    if (self.rewatching) {
        NSLog(@"Title is being rewatched.");
    }
}
- (int)getUserRatingType {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/users?filter[name]=%@", [[NSUserDefaults standardUserDefaults] valueForKey:@"loggedinusername"]]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    // Get Information
    [request startRequest];
    NSDictionary * d;
    long statusCode = [request getStatusCode];
    if (statusCode == 200 || statusCode == 201 ) {
        NSError * jerror;
        d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&jerror];
        if (((NSArray *)d[@"data"]).count > 0) {
            d = [NSArray arrayWithArray:d[@"data"]][0];
            NSString *ratingtype = d[@"attributes"][@"ratingSystem"];
            if ([ratingtype isEqualToString:@"simple"]) {
                return ratingSimple;
            }
            else if ([ratingtype isEqualToString:@"standard"]) {
                return ratingStandard;
            }
            else if ([ratingtype isEqualToString:@"advanced"]) {
                return ratingAdvanced;
            }
        }
    }
    return ratingSimple;
}
@end
