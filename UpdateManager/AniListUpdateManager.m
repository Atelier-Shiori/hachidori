//
//  AniListUpdateManager.m
//  Hachidori
//
//  Created by 香風智乃 on 1/15/19.
//

#import "AniListUpdateManager.h"
#import "DetectedScrobbleStatus.h"
#import "AniListConstants.h"
#import "LastScrobbleStatus.h"
#import <AFNetworking/AFNetworking.h>
#import "Hachidori.h"

@implementation AniListUpdateManager
- (int)anilistperformupdate:(NSString *)titleid {
    // Update the title
    // Set up Request
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getFirstAccount:1].accessToken] forHTTPHeaderField:@"Authorization"];
    //Set Status
    BOOL tmprewatching;
    long tmprewatchedcount;
    NSString * tmpWatchStatus;
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    if (self.detectedscrobble.EntryID) {
        [attributes setValue:self.detectedscrobble.EntryID forKey:@"id"];
    }
    else {
        [attributes setValue:titleid forKey:@"mediaid"];
    }
    [attributes setValue:@(self.detectedscrobble.DetectedEpisode.intValue) forKey:@"progress"];
    // Set Start Date
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"yyyy-MM-dd";
    if (self.detectedscrobble.startDate.length == 0 && !self.detectedscrobble.rewatching && (!self.detectedscrobble.EntryID || [self.detectedscrobble.WatchStatus isEqualToString:@"plan to watch"])) {
        NSString *tmpstr = [df stringFromDate:[NSDate date]];
        attributes[@"startedAt"] = @{@"year" : [tmpstr substringWithRange:NSMakeRange(0, 4)], @"month" : [tmpstr substringWithRange:NSMakeRange(5, 2)], @"day" : [tmpstr substringWithRange:NSMakeRange(8, 2)]};
    }
    if (self.detectedscrobble.DetectedEpisode.intValue == self.detectedscrobble.TotalEpisodes) {
        //Set Title State
        tmpWatchStatus = @"completed";
        // Since Detected Episode = Total Episode, set the status as "Complete"
        [attributes setValue:tmpWatchStatus.uppercaseString forKey:@"status"];
        // Set end date
        if (self.detectedscrobble.endDate.length == 0 && !self.detectedscrobble.rewatching) {
            NSString *tmpstr = [df stringFromDate:[NSDate date]];
            attributes[@"completedAt"] = @{@"year" : [tmpstr substringWithRange:NSMakeRange(0, 4)], @"month" : [tmpstr substringWithRange:NSMakeRange(5, 2)], @"day" : [tmpstr substringWithRange:NSMakeRange(8, 2)]};
        }
        //Set rewatch status to false
        tmprewatching = false;
        if (self.detectedscrobble.rewatching) {
            // Increment rewatch count
            tmprewatchedcount = self.detectedscrobble.rewatchcount + 1;
            [attributes setValue:@(tmprewatchedcount).stringValue forKey:@"repeat"];
        }
        else if (self.detectedscrobble.DetectedEpisode.intValue == self.detectedscrobble.DetectedCurrentEpisode && self.detectedscrobble.DetectedCurrentEpisode == self.detectedscrobble.TotalEpisodes) {
            //Increment Rewatch Count only
            tmprewatchedcount = self.detectedscrobble.rewatchcount + 1;
            [attributes setValue:@(tmprewatchedcount).stringValue forKey:@"repeat"];
        }
    }
    else if ([self.detectedscrobble.WatchStatus isEqualToString:@"completed"] && self.detectedscrobble.DetectedEpisode.intValue < self.detectedscrobble.TotalEpisodes) {
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
        tmprewatching = self.detectedscrobble.rewatching;
    }
    // Set rewatch status in form data
    [attributes setValue:@(self.detectedscrobble.rewatchcount) forKey:@"repeat"];
    if (tmprewatching) {
        [attributes setValue:@"REPEATING" forKey:@"status"];
    }
    // Set existing score to prevent the score from being erased.
    [attributes setValue:@(self.detectedscrobble.TitleScore) forKey:@"score"];
    //Privacy
    [attributes setValue:@(self.detectedscrobble.isPrivate) forKey:@"private"];
    
    // Notes
    [attributes setValue:self.detectedscrobble.TitleNotes forKey:@"notes"];
    
    // Assemble JSON
    NSURLSessionDataTask *task;
    NSError *error;
    // Use the appropriate graphQL query to update list entry.
    NSString *query = self.detectedscrobble.EntryID ? kAnilistExUpdateAnimeListEntryAdvanced : kAnilistUpdateAnimeListEntryAdvanced;
    if (attributes[@"startedAt"] && !attributes[@"completedAt"]) {
        query = self.detectedscrobble.EntryID ? kAnilistExUpdateAnimeListEntryAdvancedStartDate : kAnilistUpdateAnimeListEntryAdvancedStartDate;
    }
    if (!attributes[@"startedAt"] && attributes[@"completedAt"]) {
        query = self.detectedscrobble.EntryID ? kAnilistExUpdateAnimeListEntryAdvancedEndDate : kAnilistUpdateAnimeListEntryAdvancedEndDate;
    }
    else if (attributes[@"startedAt"] && attributes[@"completedAt"]) {
        query = self.detectedscrobble.EntryID ? kAnilistExUpdateAnimeListEntryAdvancedBothDate : kAnilistUpdateAnimeListEntryAdvancedBothDate;
    }
    NSDictionary *parameters = @{@"query" : query, @"variables" : attributes};
    id responseobject = [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:parameters headers:@{} task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    switch (statusCode) {
        case 201:
        case 200:
            // Store Scrobbled Title and Episode
            self.lastscrobble = [LastScrobbleStatus new];
            [self.lastscrobble transferDetectedScrobble:self.detectedscrobble];
            self.lastscrobble.DetectedCurrentEpisode = self.lastscrobble.LastScrobbledEpisode.intValue;
            self.lastscrobble.rewatching = tmprewatching;
            self.lastscrobble.WatchStatus = tmpWatchStatus;
            self.lastscrobble.LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",self.lastscrobble.LastScrobbledInfo[@"title"]];
            self.lastscrobble.confirmed = true;
            if (self.lastscrobble.LastScrobbledTitleNew) {
                if ([Hachidori currentService] == 1) {
                    self.lastscrobble.EntryID = ((NSNumber *)responseobject[@"data"][@"SaveMediaListEntry"][@"id"]).stringValue;
                }
                return ScrobblerAddTitleSuccessful;
            }
            // Update Successful
            return ScrobblerUpdateSuccessful;
        default:
            // Update Unsuccessful
            NSLog(@"Update failed: %@", error.localizedDescription);
            if (self.detectedscrobble.LastScrobbledTitleNew) {
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
    [self.asyncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getFirstAccount:1].accessToken] forHTTPHeaderField:@"Authorization"];
    //generate json
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    [attributes setValue:self.lastscrobble.EntryID forKey:@"id"];
    //Set current episode
    if (episode.intValue != self.lastscrobble.DetectedCurrentEpisode) {
        [attributes setValue:episode forKey:@"progress"];
    }
    //Set new watch status
    [attributes setValue:[self convertWatchStatus:showwatchstatus] forKey:@"status"];
    // Set rewatch status in form data
    [attributes setValue:@(self.lastscrobble.rewatchcount) forKey:@"repeat"];
    if (self.lastscrobble.rewatching) {
        [attributes setValue:@"REPEATING" forKey:@"status"];
    }
    //Set new score.
    [attributes setValue:@(showscore)forKey:@"score"];
    //Set new note
    [attributes setValue:note forKey:@"notes"];
    //Privacy
    [attributes setValue:@(privatevalue) forKey:@"private"];
    // Do Update
    [self.asyncmanager POST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistExUpdateAnimeListEntryAdvanced, @"variables" : attributes} headers:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            //Set New Values
            self.lastscrobble.TitleScore = showscore;
            self.lastscrobble.WatchStatus = showwatchstatus;
            self.lastscrobble.TitleNotes = note.length > 0 ? note : @"";
            self.lastscrobble.isPrivate = privatevalue;
            self.lastscrobble.LastScrobbledEpisode = episode;
            self.lastscrobble.DetectedCurrentEpisode = episode.intValue;
        if ([Hachidori currentService] == 1) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"UpdateDiscordStatus" object:self.lastscrobble];
            [NSNotificationCenter.defaultCenter postNotificationName:@"TwitterUpdateStatusTweet" object:self.lastscrobble];
        }
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
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getFirstAccount:1].accessToken] forHTTPHeaderField:@"Authorization"];
    //generate json
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    [attributes setValue:self.lastscrobble.AniID forKey:@"mediaid"];
    //Set current episode to total episodes
    [attributes setValue:@(self.lastscrobble.TotalEpisodes).stringValue forKey:@"progress"];
    //Revert watch status to complete
    [attributes setValue:@"COMPLETED" forKey:@"status"];
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    NSDictionary *parameters = @{@"query" : kAnilistUpdateAnimeListEntrySimple, @"variables" : attributes.copy};
    [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:parameters headers:@{} task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    switch (statusCode) {
        case 200:
        case 201:
            //Set New Values
            self.lastscrobble.rewatching = false;
            self.lastscrobble.WatchStatus = @"completed";
            self.lastscrobble.LastScrobbledEpisode = @(self.lastscrobble.TotalEpisodes).stringValue;
            self.lastscrobble.DetectedCurrentEpisode = self.lastscrobble.TotalEpisodes;
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
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getFirstAccount:1].accessToken] forHTTPHeaderField:@"Authorization"];
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    [self.syncmanager syncPOST:@"https://graphql.anilist.co"  parameters:@{@"query" : kAnilistDeleteListEntry, @"variables" : @{@"id" : self.lastscrobble.EntryID}} headers:@{} task:&task error:&error];
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
    self.lastscrobble = [LastScrobbleStatus new];
    [self.lastscrobble transferDetectedScrobble:self.detectedscrobble];
    self.lastscrobble.LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",self.lastscrobble.LastScrobbledInfo[@"title"]];
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
