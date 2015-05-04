//
//  Hachidori+UserStatus.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+UserStatus.h"
#import "EasyNSURLConnection.h"

@implementation Hachidori (UserStatus)
-(BOOL)checkstatus:(NSString *)titleid {
    NSLog(@"Checking %@", titleid);
    // Update the title
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/libraries/%@", titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    [request addFormData:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
    // Get Information
    [request startFormRequest];
    NSDictionary * d;
    long statusCode = [request getStatusCode];
    NSError * error = [request getError];
    if (statusCode == 200 || statusCode == 201 ) {
        online = true;
        //return Data
        NSError * jerror;
        d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&jerror];
        if ([d count] > 0) {
            NSLog(@"Title on list");
            [self populateStatusData:d];
        }
        else{
            NSLog(@"Title not on list");
            WatchStatus = @"currently-watching";
            LastScrobbledInfo = [self retrieveAnimeInfo:AniID];
            DetectedCurrentEpisode = 0;
            TitleScore  = 0;
            isPrivate = [defaults boolForKey:@"setprivate"];
            TitleNotes = @"";
            LastScrobbledTitleNew = true;
            rewatching = false;
            rewatchcount = 0;
        }
        if (LastScrobbledInfo[@"episode_count"] == [NSNull null]) { // To prevent the scrobbler from failing because there is no episode total.
            TotalEpisodes = 0; // No Episode Total, Set to 0.
        }
        else { // Episode Total Exists
            TotalEpisodes = [(NSNumber *)LastScrobbledInfo[@"episode_count"] intValue];
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
-(NSDictionary *)retrieveAnimeInfo:(NSString *)slug{
    NSLog(@"Getting Additional Info");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/anime/%@", slug]];
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
        return d;
    }
    else{
        NSDictionary * d = [[NSDictionary alloc] init];
        return d;
    }
}
-(void)populateStatusData:(NSDictionary *)d{
    // Info is there.
    NSDictionary * tmpinfo = d[@"anime"];
    WatchStatus = d[@"status"];
    //Get Notes;
    if (d[@"notes"] == [NSNull null]) {
        TitleNotes = @"";
    }
    else {
        TitleNotes = d[@"notes"];
    }
    // Get Rating
    NSDictionary * rating = d[@"rating"];
    if (rating[@"value"] == [NSNull null]){
        // Score is null, set to 0
        TitleScore = 0;
    }
    else {
        TitleScore = [(NSNumber *)rating[@"value"] floatValue];
    }
    // Rewatch Information
    rewatching = [d[@"rewatching"] boolValue];
    rewatchcount = [d[@"rewatched_times"] longValue];
    // Privacy Settings
    isPrivate = [d[@"private"] boolValue];
    DetectedCurrentEpisode = [(NSNumber *)d[@"episodes_watched"] intValue];
    LastScrobbledInfo = tmpinfo;
    LastScrobbledTitleNew = false;
}
@end
