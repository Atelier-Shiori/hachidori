//
//  Hachidori+MALSync.m
//  Hachidori
//
//  Created by アナスタシア on 2016/04/17.
//  Copyright 2009-2016 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+MALSync.h"
#import "Hachidori+Keychain.h"
#import "Utility.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>

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
    self.MALID = [self getMALID];
    NSLog(@"Checking Status on MyAnimeList");
    //Set Search API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1/anime/%@?mine=1",self.MALApiUrl, self.MALID]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    request.headers = @{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
    //Perform Search
    [request startRequest];
    // Get Status Code
    long statusCode = [request getStatusCode];
    NSError * error = [request getError]; // Error Detection
    if (statusCode == 200 ) {
        NSError* jerror;
        NSDictionary *animeinfo = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:NSJSONReadingMutableContainers error:&jerror];
        // Check if title needs to be added or not.
        bool onlist = animeinfo[@"watched_status"] == [NSNull null];
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
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1/animelist/anime/%@", self.MALApiUrl, self.MALID]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    request.headers = @{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
    [request setPostMethod:@"PUT"];
    // Set info
    [request addFormData:self.LastScrobbledEpisode forKey:@"episodes"];
    //Rewatch Status
    [request addFormData:self.rewatching ? @"1" : @"0" forKey:@"is_rewatching"];
    [request addFormData:@(self.rewatchcount).stringValue forKey:@"rewatch_count"];
    [request addFormData:self.TitleNotes forKey:@"comments"];
    
    //Set Status
    [request addFormData:[self.WatchStatus isEqual:@"current"] ? @"watching" : self.WatchStatus forKey:@"status"];
    
    // Convert score
    int tmpscore = [Utility translateKitsuTwentyScoreToMAL:self.TitleScore];
    [request addFormData:@(tmpscore).stringValue forKey:@"score"];
    
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
- (BOOL)addtitle {
    // Add the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/2/animelist/anime", self.MALApiUrl]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    request.headers = @{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
    [request addFormData:self.MALID forKey:@"anime_id"];
    [request addFormData:self.LastScrobbledEpisode forKey:@"episodes"];
    
    // Check if the detected episode is equal to total episodes. If so, set it as complete (mostly for specials and movies)
    //Set Status
    [request addFormData:[self.WatchStatus isEqual:@"current"] ? @"watching" : self.WatchStatus forKey:@"status"];
    
    //Convert score
    int tmpscore = [Utility translateKitsuTwentyScoreToMAL:self.TitleScore];
    [request addFormData:@(tmpscore).stringValue forKey:@"score"];
    
    // Do Update
    [request startFormRequest];

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
- (NSString *)getMALID {
    NSLog(@"Retrieving MyAnimeList Anime ID from Kitsu...");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/anime/%@/mappings", self.AniID]];
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
        for (NSDictionary * m in mappings) {
            if ([[NSString stringWithFormat:@"%@",[m[@"attributes"] valueForKey:@"externalSite"]] isEqualToString:@"myanimelist/anime"]) {
                return [NSString stringWithFormat:@"%@",[m[@"attributes"] valueForKey:@"externalId"]];
            }
        }
    }
    return @"";
}
@end
