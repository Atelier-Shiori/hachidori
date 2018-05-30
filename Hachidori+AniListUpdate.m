//
//  Hachidori+AniListUpdate.m
//  Hachidori
//
//  Created by 天々座理世 on 2018/05/28.
//
#import <AFNetworking/AFNetworking.h>
#import "Hachidori+AniListUpdate.h"
#import "Hachidori+Twitter.h"
#import "Hachidori+Discord.h"

@implementation Hachidori (AniListUpdate)
- (int)anilistperformupdate:(NSString *)titleid {
    // Update the title
    // Set up Request
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    //Set Status
    BOOL tmprewatching;
    long tmprewatchedcount;
    NSString * tmpWatchStatus;
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    [attributes setValue:titleid forKey:@"mediaid"];
    [attributes setValue:self.DetectedEpisode forKey:@"progress"];
    if (self.DetectedEpisode.intValue == self.TotalEpisodes) {
        //Set Title State
        tmpWatchStatus = @"completed";
        // Since Detected Episode = Total Episode, set the status as "Complete"
        [attributes setValue:tmpWatchStatus.uppercaseString forKey:@"status"];
        //Set rewatch status to false
        tmprewatching = false;
        if (self.rewatching) {
            // Increment rewatch count
            tmprewatchedcount = self.rewatchcount + 1;
            [attributes setValue:@(tmprewatchedcount).stringValue forKey:@"repeat"];
        }
        else if (self.DetectedEpisode.intValue == self.DetectedCurrentEpisode && self.DetectedCurrentEpisode == self.TotalEpisodes) {
            //Increment Rewatch Count only
            tmprewatchedcount = self.rewatchcount + 1;
            [attributes setValue:@(tmprewatchedcount).stringValue forKey:@"repeat"];
        }
    }
    else if ([self.WatchStatus isEqualToString:@"completed"] && self.DetectedEpisode.intValue < self.TotalEpisodes) {
        //Set rewatch status to true
        tmprewatching = true;
        //Set Title State to currently watching
        tmpWatchStatus = @"watching";
        [attributes setValue:@"CURRENT" forKey:@"status"];
    }
    else {
        //Set Title State to currently watching
        tmpWatchStatus = @"watching";
        // Still Watching
        [attributes setValue:@"CURRENT" forKey:@"status"];
        tmprewatching = self.rewatching;
    }
    // Set rewatch status in form data
    [attributes setValue:@(self.rewatchcount) forKey:@"repeat"];
    if (tmprewatching) {
        [attributes setValue:@"REPEATING" forKey:@"status"];
    }
    // Set existing score to prevent the score from being erased.
    [attributes setValue:@(self.TitleScore) forKey:@"score"];
    //Privacy
    [attributes setValue:self.isPrivate ? @"true" : @"false" forKey:@"private"];
    
    // Notes
    [attributes setValue:self.TitleNotes forKey:@"notes"];
    
    // Assemble JSON
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject;
    NSDictionary *parameters = @{@"query" : kAnilistUpdateAnimeListEntryAdvanced, @"variables" : attributes.copy};
    responseObject = [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:parameters task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    switch (statusCode) {
        case 201:
        case 200:
            // Store Scrobbled Title and Episode
            self.LastScrobbledTitle = self.DetectedTitle;
            self.LastScrobbledEpisode = self.DetectedEpisode;
            self.DetectedCurrentEpisode = self.LastScrobbledEpisode.intValue;
            self.LastScrobbledSource = self.DetectedSource;
            self.rewatching = tmprewatching;
            self.WatchStatus = tmpWatchStatus;
            if (self.confirmed) { // Will only store actual title if confirmation feature is not turned on
                // Store Actual Title
                self.LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",self.LastScrobbledInfo[@"title"]];
            }
            self.confirmed = true;
            if (self.LastScrobbledTitleNew) {
                return ScrobblerAddTitleSuccessful;
            }
            // Update Successful
            return ScrobblerUpdateSuccessful;
        default:
            // Update Unsuccessful
            NSLog(@"Update failed: %@", error.localizedDescription);
            if (self.LastScrobbledTitleNew) {
                return ScrobblerAddTitleFailed;
            }
            return ScrobblerUpdateFailed;
    }
}
- (void)anilistupdatestatus:(NSString *)titleid
                    episode:(NSString *)episode
                      score:(int)showscore
                watchstatus:(NSString*)showwatchstatus
                      notes:(NSString*)note
                  isPrivate:(BOOL)privatevalue
                 completion:(void (^)(bool success))completionhandler
{
    NSLog(@"Updating Status for %@", titleid);
    // Update the title
    [self.asyncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    //generate json
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    [attributes setValue:self.AniID forKey:@"mediaid"];
    //Set current episode
    if (episode.intValue != self.DetectedCurrentEpisode) {
        [attributes setValue:episode forKey:@"progress"];
    }
    //Set new watch status
    [attributes setValue:[self convertWatchStatus:showwatchstatus] forKey:@"status"];
    // Set rewatch status in form data
    [attributes setValue:@(self.rewatchcount) forKey:@"repeat"];
    if (self.rewatching) {
        [attributes setValue:@"REPEATING" forKey:@"status"];
    }
    //Set new score.
    [attributes setValue:showscore > 0 ? [NSString stringWithFormat:@"%i", showscore]:[NSNull null] forKey:@"score"];
    //Set new note
    [attributes setValue:note forKey:@"notes"];
    //Privacy
    [attributes setValue:@(privatevalue) forKey:@"private"];
    // Do Update
    [self.asyncmanager POST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistUpdateAnimeListEntryAdvanced, @"variables" : attributes} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //Set New Values
        self.TitleScore = showscore;
        self.WatchStatus = showwatchstatus;
        self.TitleNotes = note;
        self.isPrivate = privatevalue;
        self.LastScrobbledEpisode = episode;
        self.DetectedCurrentEpisode = episode.intValue;
        [self sendDiscordPresence];
        [self postupdatestatustweet];
        completionhandler(true);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@", error);
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",errResponse);
        completionhandler(false);
    }];
}
- (BOOL)aniliststopRewatching:(NSString *)titleid {
    NSLog(@"Reverting rewatch for %@", titleid);
    // Update the title
    // Set up Request
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    //generate json
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    [attributes setValue:self.AniID forKey:@"mediaid"];
    //Set current episode to total episodes
    [attributes setValue:@(self.TotalEpisodes).stringValue forKey:@"progress"];
    //Revert watch status to complete
    [attributes setValue:@"COMPLETED" forKey:@"status"];
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    NSDictionary *parameters = @{@"query" : kAnilistUpdateAnimeListEntrySimple, @"variables" : attributes.copy};
    id responseObject = [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:parameters task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    switch (statusCode) {
        case 200:
        case 201:
            //Set New Values
            self.rewatching = false;
            self.WatchStatus = @"completed";
            self.LastScrobbledEpisode = @(self.TotalEpisodes).stringValue;
            self.DetectedCurrentEpisode = self.TotalEpisodes;
            return true;
        default:
            // Rewatch revert unsuccessful
            return false;
            break;
    }
    return false;
}
- (bool)anilistremovetitle:(NSString *)titleid {
    NSLog(@"Removing %@", titleid);
    // Removes title
    // Set up Request
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject = [self.syncmanager syncPOST:@"https://graphql.anilist.co"  parameters:@{@"query" : kAnilistDeleteListEntry, @"variables" : @{@"id" : self.EntryID}} task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    switch (statusCode) {
        case 204:
        case 200:
            return true;
        default:
            // Update Unsuccessful
            NSLog(@"Delete failed: %@", error.localizedDescription);
            return false;
    }
    return false;
}
- (void)aniliststoreLastScrobbled {
    self.LastScrobbledTitle = self.DetectedTitle;
    self.LastScrobbledEpisode = self.DetectedEpisode;
    self.LastScrobbledSource = self.DetectedSource;
    self.LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",self.LastScrobbledInfo[@"title"]];
}
- (NSString *)convertWatchStatus:(NSString *)status {
    if ([status isEqualToString:@"watching"]) {
        return @"CURRENT";
    }
    else if ([status isEqualToString:@"watching"]) {
        return @"REPEATING";
    }
    else if ([status isEqualToString:@"on-hold"]) {
        return @"PAUSED";
    }
    else if ([status isEqualToString:@"plan to watch"]) {
        return @"PLANNING";
    }
    return status.uppercaseString;
}
@end
