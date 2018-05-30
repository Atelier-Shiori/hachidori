//
//  Hachidori+KitsuUpdate.m
//  Hachidori
//
//  Created by 天々座理世 on 2018/05/28.
//

#import "Hachidori+KitsuUpdate.h"
#import <AFNetworking/AFNetworking.h>
#import "Hachidori+Twitter.h"
#import "Hachidori+Discord.h"

@implementation Hachidori (KitsuUpdate)
- (int)kitsuperformupdate:(NSString *)titleid {
    // Update the title
    //Set library/scrobble API
    NSString * updatemethod = self.EntryID ? [NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries/%@", self.EntryID] : @"https://kitsu.io/api/edge/library-entries/";
    // Set up Request
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    //Set Status
    BOOL tmprewatching;
    long tmprewatchedcount;
    NSString * tmpWatchStatus;
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    NSMutableDictionary * tmpd = [NSMutableDictionary new];
    if (self.EntryID) {
        [tmpd setValue:self.EntryID forKey:@"id"];
    }
    else {
        //Create relationship JSON for a new library entry
        NSDictionary * userd =  @{@"data" : @{@"id" : [self getUserid], @"type" : @"users"}};
        NSDictionary * mediad = @{@"data" : @{@"id" : self.AniID, @"type" : @"anime"}};
        NSDictionary * relationshipsd = @{@"user" : userd, @"media" : mediad};
        tmpd[@"relationships"] = relationshipsd;
    }
    [tmpd setValue:@"libraryEntries" forKey:@"type"];
    [attributes setValue:self.DetectedEpisode forKey:@"progress"];
    if (self.DetectedEpisode.intValue == self.TotalEpisodes) {
        //Set Title State
        tmpWatchStatus = @"completed";
        // Since Detected Episode = Total Episode, set the status as "Complete"
        [attributes setValue:tmpWatchStatus forKey:@"status"];
        //Set rewatch status to false
        tmprewatching = false;
        if (self.rewatching) {
            // Increment rewatch count
            tmprewatchedcount = self.rewatchcount + 1;
            [attributes setValue:@(tmprewatchedcount).stringValue forKey:@"reconsumeCount"];
        }
        else if (self.DetectedEpisode.intValue == self.DetectedCurrentEpisode && self.DetectedCurrentEpisode == self.TotalEpisodes) {
            //Increment Rewatch Count only
            tmprewatchedcount = self.rewatchcount + 1;
            [attributes setValue:@(tmprewatchedcount).stringValue forKey:@"reconsumeCount"];
        }
    }
    else if ([self.WatchStatus isEqualToString:@"completed"] && self.DetectedEpisode.intValue < self.TotalEpisodes) {
        //Set rewatch status to true
        tmprewatching = true;
        //Set Title State to currently watching
        tmpWatchStatus = @"watching";
        [attributes setValue:@"current" forKey:@"status"];
    }
    else {
        //Set Title State to currently watching
        tmpWatchStatus = @"watching";
        // Still Watching
        [attributes setValue:@"current" forKey:@"status"];
        tmprewatching = self.rewatching;
    }
    // Set rewatch status in form data
    [attributes setValue:tmprewatching ? @"true" : @"false" forKey:@"reconsuming"];
    // Set existing score to prevent the score from being erased.
    [attributes setValue:self.TitleScore > 0 ? @(self.TitleScore) : [NSNull null] forKey:@"ratingTwenty"];
    //Privacy
    [attributes setValue:self.isPrivate ? @"true" : @"false" forKey:@"private"];
    
    // Assemble JSON
    [tmpd setValue:attributes forKey:@"attributes"];
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject;
    NSDictionary *parameters = @{@"data" : tmpd.copy};
    if (self.EntryID) {
        responseObject = [self.syncmanager syncPATCH:updatemethod parameters:parameters task:&task error:&error];
    }
    else {
        responseObject = [self.syncmanager syncPOST:updatemethod parameters:parameters task:&task error:&error];
    }
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
            if (!self.EntryID) {
                // Retrieve new entry id
                NSDictionary *d = responseObject[@"data"];
                self.EntryID = d[@"id"];
            }
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
- (void)kitsuupdatestatus:(NSString *)titleid
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
    NSMutableDictionary * tmpd = [NSMutableDictionary new];
    [tmpd setValue:self.EntryID forKey:@"id"];
    [tmpd setValue:@"libraryEntries" forKey:@"type"];
    //Set current episode
    if (episode.intValue != self.DetectedCurrentEpisode) {
        [attributes setValue:episode forKey:@"progress"];
    }
    //Set new watch status
    [attributes setValue:[self convertKitsuWatchStatus:showwatchstatus] forKey:@"status"];
    //Set new score.
    [attributes setValue:showscore > 0 ? [NSString stringWithFormat:@"%i", showscore]:[NSNull null] forKey:@"ratingTwenty"];
    [attributes setValue:[NSNull null] forKey:@"rating"];
    //Set new note
    [attributes setValue:note forKey:@"notes"];
    //Privacy
    [attributes setValue:privatevalue ? @"true" : @"false" forKey:@"private"];
    // Assemble JSON
    [tmpd setValue:attributes forKey:@"attributes"];
    // Do Update
    [self.asyncmanager PATCH:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries/%@", self.EntryID] parameters:@{@"data":tmpd} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //Set New Values
        self.TitleScore = showscore;
        self.WatchStatus = showwatchstatus;
        self.TitleNotes = note;
        self.isPrivate = privatevalue;
        self.LastScrobbledEpisode = episode;
        self.DetectedCurrentEpisode = episode.intValue;
        [self postupdatestatustweet];
        [self sendDiscordPresence];
        completionhandler(true);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@", error);
        completionhandler(false);
    }];
}
- (BOOL)kitsustopRewatching:(NSString *)titleid {
    NSLog(@"Reverting rewatch for %@", titleid);
    // Update the title
    // Set up Request
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    //generate json
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    NSMutableDictionary * tmpd = [NSMutableDictionary new];
    [tmpd setValue:self.EntryID forKey:@"id"];
    [tmpd setValue:@"libraryEntries" forKey:@"type"];
    //Set current episode to total episodes
    [attributes setValue:@(self.TotalEpisodes).stringValue forKey:@"progress"];
    //Revert watch status to complete
    [attributes setValue:@"completed" forKey:@"status"];
    //Set Rewatch status to false
    [attributes setValue:@"false" forKey:@"reconsuming"];
    // Assemble JSON
    [tmpd setValue:attributes forKey:@"attributes"];
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject = [self.syncmanager syncPATCH:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries/%@", self.EntryID] parameters:@{@"data" : tmpd} task:&task error:&error];
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
- (bool)kitsuremovetitle:(NSString *)titleid {
    NSLog(@"Removing %@", titleid);
    // Removes title
    // Set up Request
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [self getCurrentFirstAccount].accessToken] forHTTPHeaderField:@"Authorization"];
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject = [self.syncmanager syncDELETE:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries/%@", self.EntryID] parameters:nil task:&task error:&error];
    // Get Status Code
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    switch (statusCode) {
        case 204:
            return true;
        default:
            // Update Unsuccessful
            NSLog(@"Delete failed: %@", error.localizedDescription);
            return false;
    }
    return false;
}
- (void)kitsustoreLastScrobbled {
    self.LastScrobbledTitle = self.DetectedTitle;
    self.LastScrobbledEpisode = self.DetectedEpisode;
    self.LastScrobbledSource = self.DetectedSource;
    self.slug = self.LastScrobbledInfo[@"slug"];
    self.LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",self.LastScrobbledInfo[@"title"]];
}
- (NSString *)convertKitsuWatchStatus:(NSString *)status {
    if ([status isEqualToString:@"watching"]) {
        return @"current";
    }
    else if ([status isEqualToString:@"on-hold"]) {
        return @"on_hold";
    }
    else if ([status isEqualToString:@"plan to watch"]) {
        return @"planned";
    }
    return status;
}
@end
