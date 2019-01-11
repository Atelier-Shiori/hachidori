//
//  Hachidori+UserStatus.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2018 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+UserStatus.h"
#import "AtarashiiAPIListFormatKitsu.h"
#import "AtarashiiAPIListFormatAniList.h"
#import <AFNetworking/AFNetworking.h>
#import "Utility.h"

@implementation Hachidori (UserStatus)
- (BOOL)checkstatus:(NSString *)titleid {
    NSLog(@"Checking %@", titleid);
    // Update the title
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set OAuth Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject;
    switch (self.currentService) {
        case 0:
            responseObject = [self.syncmanager syncGET:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries?filter[user-id]=%@&filter[media-id]=%@", [self getUserid], titleid] parameters:nil task:&task error:&error];
            break;
        case 1:
            responseObject = [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistAnimeSingleEntry, @"variables" : @{@"id" : [self getUserid], @"mediaid" : titleid}} task:&task error:&error];
            break;
        default:
            return NO;
    }
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    if (statusCode == 200 || statusCode == 201 ) {
        NSDictionary *entry;
        switch (self.currentService) {
            case 0:
                entry = [AtarashiiAPIListFormatKitsu KitsuAnimeListEntrytoAtarashii:responseObject];
                break;
            case 1:
                if (responseObject[@"data"] && responseObject[@"data"] != [NSNull null]) {
                    entry = [AtarashiiAPIListFormatAniList AniListtoAtarashiiAnimeSingle:responseObject[@"data"][@"AnimeList"][@"mediaList"]];
                }
                break;
            default:
                return NO;
        }
        //return Data
        if (entry) {
            self.detectedscrobble.EntryID = entry[@"entryid"];
            NSLog(@"Title on list");
            [self populateStatusData:entry id:titleid];
        }
        else {
            NSLog(@"Title not on list");
            self.detectedscrobble.EntryID = nil;
            self.detectedscrobble.WatchStatus = @"watching";
            self.detectedscrobble.LastScrobbledInfo = [self retrieveAnimeInfo:self.detectedscrobble.AniID];
            self.detectedscrobble.DetectedCurrentEpisode = 0;
            self.detectedscrobble.TitleScore  = 0;
            self.detectedscrobble.isPrivate = [defaults boolForKey:@"setprivate"];
            self.detectedscrobble.TitleNotes = @"";
            self.detectedscrobble.startDate = @"";
            self.detectedscrobble.endDate = @"";
            self.detectedscrobble.LastScrobbledTitleNew = true;
            self.detectedscrobble.rewatching = false;
            self.detectedscrobble.rewatchcount = 0;
        }
        // Set air status
        self.detectedscrobble.airing = ((self.detectedscrobble.LastScrobbledInfo[@"start_date"] != [NSNull null] && ((((NSString *)self.detectedscrobble.LastScrobbledInfo[@"start_date"]).length > 0 && self.detectedscrobble.LastScrobbledInfo[@"end_date"] == [NSNull null]))) || [(NSString *)self.detectedscrobble.LastScrobbledInfo[@"status"] isEqualToString:@"currently airing"]);
        self.detectedscrobble.completedairing = ((self.detectedscrobble.LastScrobbledInfo[@"start_date"] != [NSNull null] && self.detectedscrobble.LastScrobbledInfo[@"end_date"] != [NSNull null]) && (((NSString *)self.detectedscrobble.LastScrobbledInfo[@"start_date"]).length > 0 && ((NSString *)self.detectedscrobble.LastScrobbledInfo[@"end_date"]).length > 0)) || [(NSString *)self.detectedscrobble.LastScrobbledInfo[@"status"] isEqualToString:@"finished airing"];

        if (!self.detectedscrobble.LastScrobbledInfo[@"episodes"] || self.detectedscrobble.LastScrobbledInfo[@"episodes"] == [NSNull null]) { // To prevent the scrobbler from failing because there is no episode total.
            self.detectedscrobble.TotalEpisodes = 0; // No Episode Total, Set to 0.
        }
        else { // Episode Total Exists
            self.detectedscrobble.TotalEpisodes = ((NSNumber *)self.detectedscrobble.LastScrobbledInfo[@"episodes"]).intValue;
        }
        // New Update Confirmation
        if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && self.detectedscrobble.LastScrobbledTitleNew && !self.correcting)|| ([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !self.detectedscrobble.LastScrobbledTitleNew && !self.correcting)) {
            // Manually confirm updates
            self.detectedscrobble.confirmed = false;
        }
        else {
            // Automatically confirm updates
            self.detectedscrobble.confirmed = true;
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
- (NSDictionary *)retrieveAnimeInfo:(NSString *)aid {
    NSLog(@"Getting Additional Info");
    //Set OAuth Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject;
    switch (self.currentService) {
        case 0:
            responseObject = [self.syncmanager syncGET:[NSString stringWithFormat:@"https://kitsu.io/api/edge/anime/%@", aid] parameters:nil task:&task error:&error];
            break;
        case 1:
            responseObject = [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistTitleIdInformation, @"variables" : @{@"id" : aid, @"type" : @"ANIME"}} task:&task error:&error];
            break;
        default:
            return @{};
    }
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    if (statusCode == 200) {
        switch (self.currentService) {
            case 0:
                return [AtarashiiAPIListFormatKitsu KitsuAnimeInfotoAtarashii:responseObject];
            case 1:
                return [AtarashiiAPIListFormatAniList AniListAnimeInfotoAtarashii:responseObject];
            default:
                return @{};
        }
    }
    else {
        NSDictionary * d = @{};
        return d;
    }
}
- (void)populateStatusData:(NSDictionary *)d id:(NSString *)aid {
    // Retrieve Anime Information
    NSDictionary * tmpinfo = [self retrieveAnimeInfo:aid];
    self.detectedscrobble.WatchStatus = d[@"watched_status"];
    //Get Notes;
    if (d[@"personal_comments"] == [NSNull null] && d[@"personal_comments"]) {
        self.detectedscrobble.TitleNotes = @"";
    }
    else {
        self.detectedscrobble.TitleNotes = d[@"personal_comments"];
    }
    self.ratingtype = [self getUserRatingType];
    if (((NSNumber *)d[@"score"]).intValue != 0) {
        // If user is using the new rating system
        self.detectedscrobble.TitleScore = ((NSNumber *)d[@"score"]).intValue;
    }
    else {
        // Score is null, set to 0
        self.detectedscrobble.TitleScore = 0;
    }
    // Rewatch Information
    self.detectedscrobble.rewatching = ((NSNumber *)d[@"rewatching"]).boolValue;
    self.detectedscrobble.rewatchcount = ((NSNumber *)d[@"rewatch_count"]).longValue;
    // Privacy Settings
    self.detectedscrobble.isPrivate = ((NSNumber *)d[@"private"]).boolValue;
    self.detectedscrobble.DetectedCurrentEpisode = ((NSNumber *)d[@"watched_episodes"]).intValue;
    self.detectedscrobble.LastScrobbledInfo = tmpinfo;
    self.detectedscrobble.LastScrobbledTitleNew = false;
    self.detectedscrobble.startDate = d[@"watching_start"];
    self.detectedscrobble.endDate = d[@"watching_end"];
    if (self.detectedscrobble.rewatching) {
        NSLog(@"Title is being rewatched.");
    }
}
- (int)getUserRatingType {
    //Set OAuth Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject;
    switch (self.currentService) {
        case 0:
            responseObject = [self.syncmanager syncGET:@"https://kitsu.io/api/edge/users?filter[self]=true" parameters:nil task:&task error:&error];
            break;
        case 1:
            responseObject = [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistCurrentUsernametoUserId, @"variables" : @{}} task:&task error:&error];
            break;
        default:
            return 0;
    }
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    if (statusCode == 200 || statusCode == 201 ) {
        switch (self.currentService) {
            case 0: {
                if (((NSArray *)responseObject[@"data"]).count > 0) {
                    NSDictionary *d = [NSArray arrayWithArray:responseObject[@"data"]][0];
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
                break;
            }
            case 1: {
                if (responseObject[@"data"][@"Viewer"] != [NSNull null]) {
                    NSDictionary *d = responseObject[@"data"][@"Viewer"];
                    NSString *ratingtype = d[@"mediaListOptions"][@"scoreFormat"];
                    if ([ratingtype isEqualToString:@"POINT_100"]) {
                        return ratingPoint100;
                    }
                    else if ([ratingtype isEqualToString:@"POINT_10_DECIMAL"]) {
                        return ratingPoint10Decimal;
                    }
                    else if ([ratingtype isEqualToString:@"POINT_10"]) {
                        return ratingPoint10;
                    }
                    else if ([ratingtype isEqualToString:@"POINT_5"]) {
                        return ratingPoint5;
                    }
                    else if ([ratingtype isEqualToString:@"POINT_3"]) {
                        return ratingPoint3;
                    }
                    else {
                        return ratingPoint100;
                    }
                }
                else {
                    return ratingPoint100;
                }
                break;
            }
        }
                
    }
    return ratingSimple;
}
@end
