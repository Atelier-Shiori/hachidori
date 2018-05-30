//
//  Hachidori+UserStatus.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2018 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+UserStatus.h"
#import "AtarashiiAPIListFormatKitsu.h"
#import "AtarashiiAPIListFormatAniList.h"
#import <AFNetworking/AFNetworking.h>
#import "Hachidori+Keychain.h"
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
            self.EntryID = entry[@"entryid"];
            NSLog(@"Title on list");
            [self populateStatusData:entry id:titleid];
        }
        else {
            NSLog(@"Title not on list");
            self.EntryID = nil;
            self.WatchStatus = @"watching";
            self.LastScrobbledInfo = [self retrieveAnimeInfo:self.AniID];
            self.DetectedCurrentEpisode = 0;
            self.TitleScore  = 0;
            self.isPrivate = [defaults boolForKey:@"setprivate"];
            self.TitleNotes = @"";
            self.LastScrobbledTitleNew = true;
            self.rewatching = false;
            self.rewatchcount = 0;
        }
        if (!self.LastScrobbledInfo[@"episodes"] || self.LastScrobbledInfo[@"episodes"] == [NSNull null]) { // To prevent the scrobbler from failing because there is no episode total.
            self.TotalEpisodes = 0; // No Episode Total, Set to 0.
        }
        else { // Episode Total Exists
            self.TotalEpisodes = ((NSNumber *)self.LastScrobbledInfo[@"episodes"]).intValue;
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
    self.WatchStatus = d[@"watched_status"];
    //Get Notes;
    if (d[@"personal_comments"] == [NSNull null]) {
        self.TitleNotes = @"";
    }
    else {
        self.TitleNotes = d[@"personal_comments"];
    }
    self.ratingtype = [self getUserRatingType];
    if (d[@"score"] != 0) {
        // If user is using the new rating system
        self.TitleScore = ((NSNumber *)d[@"score"]).intValue;
    }
    else {
        // Score is null, set to 0
        self.TitleScore = 0;
    }
    // Rewatch Information
    self.rewatching = [d[@"rewatching"] boolValue];
    self.rewatchcount = [d[@"rewatch_count"] longValue];
    // Privacy Settings
    self.isPrivate = [d[@"private"] boolValue];
    self.DetectedCurrentEpisode = ((NSNumber *)d[@"watched_episodes"]).intValue;
    self.LastScrobbledInfo = tmpinfo;
    self.LastScrobbledTitleNew = false;
    if (self.rewatching) {
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
