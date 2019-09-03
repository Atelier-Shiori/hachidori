//
//  MALUpdateManager.m
//  Hachidori
//
//  Created by 香風智乃 on 8/30/19.
//

#import "MALUpdateManager.h"
#import "DetectedScrobbleStatus.h"
#import "LastScrobbleStatus.h"
#import <AFNetworking/AFNetworking.h>
#import "Hachidori.h"

@implementation MALUpdateManager
- (int)malperformupdate:(NSString *)titleid {
    BOOL tmprewatching;
    long tmprewatchedcount;
    NSString * tmpWatchStatus;
    //Set Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getFirstAccount:2].accessToken] forHTTPHeaderField:@"Authorization"];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"num_watched_episodes"] = @(self.detectedscrobble.DetectedEpisode.intValue);
    //parameters[@"num_episodes_watched"] = @(self.DetectedEpisode.intValue);
    /*
    if (([self.detectedscrobble.WatchStatus isEqualToString:@"plan to watch"] && self.detectedscrobble.DetectedCurrentEpisode == 0) || self.detectedscrobble.LastScrobbledTitleNew) {
        // Set the start date if the title's watch status is Plan to Watch and the watched episodes is zero
        [request addFormData:[Utility todaydatestring] forKey:@"start"];
    }*/
    /*
    if ([self.WatchStatus isEqualToString:@"completed"]) {
        parameters[@"end"] = [Utility todaydatestring];
    }
     */
    //Set Status
    if (self.detectedscrobble.DetectedEpisode.intValue == self.detectedscrobble.TotalEpisodes) {
        //Set Title State
        tmpWatchStatus = @"completed";
        // Since Detected Episode = Total Episode, set the status as "Complete"
        //Set rewatch status to false
        tmprewatching = false;
        // Set end date
        if (self.detectedscrobble.endDate.length == 0  && !self.detectedscrobble.rewatching) {
            //[attributes setValue:[df stringFromDate:[NSDate date]] forKey:@"finishedAt"];
        }
        if (self.detectedscrobble.rewatching) {
            // Increment rewatch count
            tmprewatchedcount = self.detectedscrobble.rewatchcount + 1;
            parameters[@"num_times_rewatched"] = @(tmprewatchedcount);
        }
        else if (self.detectedscrobble.DetectedEpisode.intValue == self.detectedscrobble.DetectedCurrentEpisode && self.detectedscrobble.DetectedCurrentEpisode == self.detectedscrobble.TotalEpisodes) {
            //Increment Rewatch Count only
            tmprewatchedcount = self.detectedscrobble.rewatchcount + 1;
            parameters[@"num_times_rewatched"] = @(tmprewatchedcount);
        }
    }
    else if ([self.detectedscrobble.WatchStatus isEqualToString:@"completed"] && self.detectedscrobble.DetectedEpisode.intValue < self.detectedscrobble.TotalEpisodes) {
        //Set rewatch status to true
        tmprewatching = true;
        //Set Title State to currently watching
        tmpWatchStatus = @"watching";
    }
    else {
        //Set Title State to currently watching
        tmpWatchStatus = @"watching";
        // Still Watching
        tmprewatching = self.detectedscrobble.rewatching;
    }
    // Set rewatch status in form data
    parameters[@"is_rewatching"] = tmprewatching ? @"true" : @"false";
    parameters[@"status"] = [[tmpWatchStatus stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    // Set existing score to prevent the score from being erased.
    parameters[@"score"] = @(self.detectedscrobble.TitleScore);
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    id responseObject = [self.syncmanager syncPUT:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%@/my_list_status", titleid] parameters:parameters task:&task error:&error];
    
    switch (((NSHTTPURLResponse *)task.response).statusCode) {
        case 200: {
            // Store Last Scrobbled Title
            self.lastscrobble = [LastScrobbleStatus new];
            [self.lastscrobble transferDetectedScrobble:self.detectedscrobble];
            self.lastscrobble.DetectedCurrentEpisode = self.lastscrobble.LastScrobbledEpisode.intValue;
            self.lastscrobble.rewatching = tmprewatching;
            self.lastscrobble.WatchStatus = tmpWatchStatus;
            self.lastscrobble.LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",self.lastscrobble.LastScrobbledInfo[@"title"]];
            self.lastscrobble.confirmed = true;
            if (self.lastscrobble.LastScrobbledTitleNew) {;
                return ScrobblerAddTitleSuccessful;
            }
            // Update Successful
            return ScrobblerUpdateSuccessful;
            }
        default: {
            // Update Unsuccessful
            NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            NSLog(@"%@",ErrorResponse);
            if (self.detectedscrobble.LastScrobbledTitleNew) {
                return ScrobblerAddTitleFailed;
            }
            return ScrobblerUpdateFailed;
            }
    }
}
- (void)malupdatestatus:(NSString *)titleid
                  episode:(NSString *)episode
                    score:(int)showscore
              watchstatus:(NSString*)showwatchstatus
                    notes:(NSString*)note
             completion:(void (^)(bool success))completionhandler {
    NSLog(@"Updating Status for %@", titleid);
    // Update the title
    //Set Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getFirstAccount:2].accessToken] forHTTPHeaderField:@"Authorization"];
    //NSDictionary *parameters = @{@"num_episodes_watched" : @(episode.intValue), @"status" : [showwatchstatus.lowercaseString stringByReplacingOccurrencesOfString:@" " withString:@"_"], @"score" : @(showscore)};
    NSDictionary *parameters = @{@"num_watched_episodes" : @(episode.intValue), @"status" : [[showwatchstatus.lowercaseString stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"-" withString:@"_"], @"score" : @(showscore)};
    // Set up request and do update
    [self.asyncmanager PUT:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%@/my_list_status", titleid] parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.lastscrobble.TitleScore = showscore;
        self.lastscrobble.WatchStatus = showwatchstatus;
        self.lastscrobble.LastScrobbledEpisode = episode;
        self.lastscrobble.DetectedCurrentEpisode = episode.intValue;
        self.lastscrobble.confirmed = true;
        completionhandler(true);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completionhandler(false);
    }];
}
- (BOOL)malstopRewatching:(NSString *)titleid {
    NSLog(@"Reverting rewatch for %@", titleid);
    // Update the title
    // Set up Request
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getFirstAccount:2].accessToken] forHTTPHeaderField:@"Authorization"];
    //generate json
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    //Set current episode to total episodes
    [attributes setValue:@(self.lastscrobble.TotalEpisodes) forKey:@"num_watched_episodes"];
    //Revert watch status to complete
    [attributes setValue:@"completed" forKey:@"status"];
    [attributes setValue:@"false" forKey:@"is_rewatching"];
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    [self.syncmanager syncPUT:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%@/my_list_status", titleid] parameters:attributes task:&task error:&error];
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
- (bool)malremovetitle:(NSString *)titleid {
    NSLog(@"Removing %@", titleid);
    //Remove title
    //Set Token
    [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Hachidori getFirstAccount:2].accessToken] forHTTPHeaderField:@"Authorization"];
    // Do Update
    NSURLSessionDataTask *task;
    NSError *error;
    [self.syncmanager syncDELETE:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%@/my_list_status", titleid] parameters:nil task:&task error:&error];
    switch (((NSHTTPURLResponse *)task.response).statusCode) {
        case 200:
        case 201:
            return true;
        default:
            // Update Unsuccessful
            NSLog(@"Delete failed: %@", error.localizedDescription);
            return false;
    }
    return false;
}
- (void)malstoreLastScrobbled {
    self.lastscrobble = [LastScrobbleStatus new];
    [self.lastscrobble transferDetectedScrobble:self.detectedscrobble];
    self.lastscrobble.LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",self.lastscrobble.LastScrobbledInfo[@"title"]];
}
@end
