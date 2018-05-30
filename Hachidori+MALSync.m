//
//  Hachidori+MALSync.m
//  Hachidori
//
//  Created by アナスタシア on 2016/04/17.
//  Copyright 2009-2016 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+MALSync.h"
#import "Hachidori+Keychain.h"
#import "Utility.h"
#import <AFNetworking/AFNetworking.h>

@implementation Hachidori (MALSync)
- (BOOL)sync {
    NSLog(@"Starting MyAnimeList Sync...");
    // Set check Date if it doesn't exist
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"credentialscheckdate"]){
        // Check credentials now if user has an account and these values are not set
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate new] forKey:@"credentialscheckdate"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"credentialsvalid"];
    }
    // Check Credentials status
    if ([self checkMALCredentials] == 0) {
        return NO;
    }
    self.MALApiUrl = [[NSUserDefaults standardUserDefaults] valueForKey:@"MALAPIURL"];
    int syncstatus = [self checkStatus];
    if (syncstatus == 1) {
        NSLog(@"Adding %@ to user's MyAnimeList library.",self.LastScrobbledActualTitle);
        return [self addtitle];
    }
    if (syncstatus == 2) {
        NSLog(@"Updating status of %@ in user's MyAnimeList library.",self.LastScrobbledActualTitle);
        return [self updatetitle];
    }
    else {
        NSLog(@"Sync Failed!");
        return NO;
    }
}
- (int)checkStatus {
    // Checks status of the entry associated to a title id
    self.MALID = [self getMALID];
    NSLog(@"Checking Status on MyAnimeList");
    [self.malmanager.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@", [self getBase64]] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject = [self.malmanager syncGET:[NSString stringWithFormat:@"%@/1/anime/%@?mine=1",self.MALApiUrl, self.MALID] parameters:nil task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    if (statusCode == 200 ) {
        // Check if title needs to be added or not.
        bool onlist = responseObject[@"watched_status"] == [NSNull null];
        NSLog(@"%@", onlist ? @"Not on MAL List" : @"Title on MAL List");
        return onlist ? 1 : 2;
    }
    else if (error != nil) {
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
- (BOOL)updatetitle {
    // Update the title
    [self.malmanager.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@", [self getBase64]] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    //Watrch Status
    parameters[@"episodes"] = self.LastScrobbledEpisode;
    parameters[@"status"] = [self.WatchStatus isEqual:@"current"] ? @"watching" : self.WatchStatus;
    //Rewatch Status
    parameters[@"is_rewatching"] = @(self.rewatching);
    parameters[@"rewatch_count"] = @(self.rewatchcount);
    parameters[@"comments"] = self.TitleNotes;
    // Convert score
    int tmpscore = [Utility translateKitsuTwentyScoreToMAL:self.TitleScore];
    parameters[@"score"] = @(tmpscore);
    id responseObject = [self.malmanager syncPUT:[NSString stringWithFormat:@"%@/1/animelist/anime/%@", self.MALApiUrl, self.MALID] parameters:parameters task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    
    switch (statusCode) {
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
- (BOOL)addtitle {
    // Add the title
    [self.malmanager.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@", [self getBase64]] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"anime_id"] = self.MALID;
    parameters[@"episodes"] = self.LastScrobbledEpisode;
    parameters[@"status"] = [self.WatchStatus isEqual:@"current"] ? @"watching" : self.WatchStatus;
    //Convert score
    int tmpscore = [Utility translateKitsuTwentyScoreToMAL:self.TitleScore];
    parameters[@"score"] = @(tmpscore);
    
    // Do Update
    id responseObject = [self.malmanager syncPUT:[NSString stringWithFormat:@"%@/2/animelist/anime", self.MALApiUrl] parameters:parameters task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;

    switch (statusCode) {
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
- (NSString *)getMALID {
    NSLog(@"Retrieving MyAnimeList Anime ID from Kitsu...");
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject = [self.syncmanager syncGET:[NSString stringWithFormat:@"https://kitsu.io/api/edge/anime/%@/mappings", self.AniID] parameters:nil task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    if (statusCode == 200) {
        NSArray * mappings = responseObject[@"data"];
        for (NSDictionary * m in mappings) {
            if ([[NSString stringWithFormat:@"%@",[m[@"attributes"] valueForKey:@"externalSite"]] isEqualToString:@"myanimelist/anime"]) {
                return [NSString stringWithFormat:@"%@",[m[@"attributes"] valueForKey:@"externalId"]];
            }
        }
    }
    return @"";
}
@end
