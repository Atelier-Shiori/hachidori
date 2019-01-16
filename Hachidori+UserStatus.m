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
- (BOOL)checkstatus:(NSString *)titleid withService:(int)service {
    NSLog(@"Checking %@", titleid);
    // Update the title
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set OAuth Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getFirstAccount:service].accessToken] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject;
    switch (service) {
        case 0:
            responseObject = [self.syncmanager syncGET:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries?filter[user-id]=%@&filter[media-id]=%@", [Hachidori getUserid:service], titleid] parameters:nil task:&task error:&error];
            break;
        case 1:
            responseObject = [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistAnimeSingleEntry, @"variables" : @{@"id" : [Hachidori getUserid:service], @"mediaid" : titleid}} task:&task error:&error];
            break;
        default:
            return NO;
    }
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    if (statusCode == 200 || statusCode == 201 ) {
        NSDictionary *entry;
        switch (service) {
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
        DetectedScrobbleStatus *dscrobblestatus = [self retrieveDetectedScrobbleForService:service];
        if (entry) {
            dscrobblestatus.EntryID = entry[@"entryid"];
            NSLog(@"Title on list");
            [self populateStatusData:entry titleid:titleid withDetectedScrobble:dscrobblestatus withService:service];
        }
        else {
            NSLog(@"Title not on list");
            dscrobblestatus.EntryID = nil;
            dscrobblestatus.WatchStatus = @"watching";
            dscrobblestatus.LastScrobbledInfo = [self retrieveAnimeInfo:dscrobblestatus.AniID withService:service];
            dscrobblestatus.DetectedCurrentEpisode = 0;
            dscrobblestatus.TitleScore  = 0;
            dscrobblestatus.isPrivate = [defaults boolForKey:@"setprivate"];
            dscrobblestatus.TitleNotes = @"";
            dscrobblestatus.startDate = @"";
            dscrobblestatus.endDate = @"";
            dscrobblestatus.LastScrobbledTitleNew = true;
            dscrobblestatus.rewatching = false;
            dscrobblestatus.rewatchcount = 0;
        }
        // Set air status
        dscrobblestatus.airing = ((dscrobblestatus.LastScrobbledInfo[@"start_date"] != [NSNull null] && ((((NSString *)dscrobblestatus.LastScrobbledInfo[@"start_date"]).length > 0 && dscrobblestatus.LastScrobbledInfo[@"end_date"] == [NSNull null]))) || [(NSString *)dscrobblestatus.LastScrobbledInfo[@"status"] isEqualToString:@"currently airing"]);
        dscrobblestatus.completedairing = ((dscrobblestatus.LastScrobbledInfo[@"start_date"] != [NSNull null] && dscrobblestatus.LastScrobbledInfo[@"end_date"] != [NSNull null]) && (((NSString *)dscrobblestatus.LastScrobbledInfo[@"start_date"]).length > 0 && ((NSString *)dscrobblestatus.LastScrobbledInfo[@"end_date"]).length > 0)) || [(NSString *)dscrobblestatus.LastScrobbledInfo[@"status"] isEqualToString:@"finished airing"];

        if (!dscrobblestatus.LastScrobbledInfo[@"episodes"] || dscrobblestatus.LastScrobbledInfo[@"episodes"] == [NSNull null]) { // To prevent the scrobbler from failing because there is no episode total.
            dscrobblestatus.TotalEpisodes = 0; // No Episode Total, Set to 0.
        }
        else { // Episode Total Exists
            dscrobblestatus.TotalEpisodes = ((NSNumber *)dscrobblestatus.LastScrobbledInfo[@"episodes"]).intValue;
        }
        // New Update Confirmation
        if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && dscrobblestatus.LastScrobbledTitleNew && !self.correcting)|| ([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !dscrobblestatus.LastScrobbledTitleNew && !self.correcting)) {
            // Manually confirm updates
            dscrobblestatus.confirmed = false;
        }
        else {
            // Automatically confirm updates
            dscrobblestatus.confirmed = true;
        }
        if (service == [Hachidori currentService]) {
            self.ratingtype = [self getUserRatingType];
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
- (NSDictionary *)retrieveAnimeInfo:(NSString *)aid withService:(int)service {
    NSLog(@"Getting Additional Info");
    //Set OAuth Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getFirstAccount:service].accessToken] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject;
    switch (service) {
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
        switch (service) {
            case 0:
                return [AtarashiiAPIListFormatKitsu KitsuAnimeInfotoAtarashii:responseObject];
            case 1:
                return [AtarashiiAPIListFormatAniList AniListAnimeInfotoAtarashii:responseObject];
            default:
                return @{};
        }
    }
    else {
        NSLog(@"%@", error.localizedDescription);
        NSDictionary * d = @{};
        return d;
    }
}
- (void)populateStatusData:(NSDictionary *)d titleid:(NSString *)aid withDetectedScrobble:(DetectedScrobbleStatus *)dscrobble withService:(int)service {
    // Retrieve Anime Information
    NSDictionary * tmpinfo = [self retrieveAnimeInfo:aid withService:service];
    dscrobble.WatchStatus = d[@"watched_status"];
    //Get Notes;
    if (d[@"personal_comments"] == [NSNull null] && d[@"personal_comments"]) {
        dscrobble.TitleNotes = @"";
    }
    else {
        dscrobble.TitleNotes = d[@"personal_comments"];
    }
    if (((NSNumber *)d[@"score"]).intValue != 0) {
        // If user is using the new rating system
        dscrobble.TitleScore = ((NSNumber *)d[@"score"]).intValue;
    }
    else {
        // Score is null, set to 0
        dscrobble.TitleScore = 0;
    }
    // Rewatch Information
    dscrobble.rewatching = ((NSNumber *)d[@"rewatching"]).boolValue;
    dscrobble.rewatchcount = ((NSNumber *)d[@"rewatch_count"]).longValue;
    // Privacy Settings
    dscrobble.isPrivate = ((NSNumber *)d[@"private"]).boolValue;
    dscrobble.DetectedCurrentEpisode = ((NSNumber *)d[@"watched_episodes"]).intValue;
    dscrobble.LastScrobbledInfo = tmpinfo;
    dscrobble.LastScrobbledTitleNew = false;
    dscrobble.startDate = d[@"watching_start"];
    dscrobble.endDate = d[@"watching_end"];
    if (dscrobble.rewatching) {
        NSLog(@"Title is being rewatched.");
    }
}

- (DetectedScrobbleStatus *)retrieveDetectedScrobbleForService:(int)service {
    switch (service) {
        case 0:
            return self.kitsumanager.detectedscrobble;
        case 1:
            return self.anilistmanager.detectedscrobble;
        default:
            return nil;
    }
}
@end
