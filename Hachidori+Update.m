//
//  Hachidori+Update.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2018 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+Update.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>

@implementation Hachidori (Update)
- (int)updatetitle:(NSString *)titleid {
    NSLog(@"Updating Title");
    if (self.LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && !self.confirmed && !self.correcting) {
        // Confirm before updating title
        [self storeLastScrobbled];
        return ScrobblerConfirmNeeded;
    }
    if (self.DetectedEpisode.intValue <= self.DetectedCurrentEpisode && (![self.WatchStatus isEqualToString:@"completed"] || ![[NSUserDefaults standardUserDefaults] boolForKey:@"RewatchEnabled"])) {
        // Already Watched, no need to scrobble
        // Store Scrobbled Title and Episode
        [self storeLastScrobbled];
        self.confirmed = true;
        return ScrobblerUpdateNotNeeded;
    }
    else if (self.DetectedEpisode.intValue == self.DetectedCurrentEpisode && self.DetectedCurrentEpisode == self.TotalEpisodes && self.TotalEpisodes > 1 && [self.WatchStatus isEqualToString:@"completed"]) {
       //Do not set rewatch status for current episode equal to total episodes.
        [self storeLastScrobbled];
        self.confirmed = true;
        return ScrobblerUpdateNotNeeded;
    }
    else if (!self.LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !self.confirmed && !self.correcting) {
        // Confirm before updating title
        [self storeLastScrobbled];
        return ScrobblerConfirmNeeded;
    }
    else {
        return [self performupdate:titleid];
    }
}
- (int)performupdate:(NSString *)titleid {
    // Update the title
    //Set library/scrobble API
    NSString * updatemethod = self.EntryID ? [NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries/%@", self.EntryID] : @"https://kitsu.io/api/edge/library-entries/";
    NSURL *url = [NSURL URLWithString:updatemethod];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set OAuth Token
    request.headers = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", [self getFirstAccount].accessToken]};
    //Set Status
    BOOL tmprewatching;
    long tmprewatchedcount;
    NSString * tmpWatchStatus;
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    NSMutableDictionary * tmpd = [NSMutableDictionary new];
    if (self.EntryID) {
        [request setPostMethod:@"PATCH"];
        [tmpd setValue:self.EntryID forKey:@"id"];
    }
    else {
        [request setPostMethod:@"POST"];
        //Create relationship JSON for a new library entry
        NSDictionary * userd =  @{@"data" : @{@"id" : [self getUserid], @"type" : @"users"}};
        NSDictionary * mediad = @{@"data" : @{@"id" : self.AniID, @"type" : @"anime"}};
        NSDictionary * relationshipsd = @{@"user" : userd, @"media" : mediad};
        tmpd[@"relationships"] = relationshipsd;
    }
    [tmpd setValue:@"libraryEntries" forKey:@"type"];
    [attributes setValue:self.DetectedEpisode forKey:@"progress"];
    if(self.DetectedEpisode.intValue == self.TotalEpisodes) {
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
        tmpWatchStatus = @"current";
        [attributes setValue:tmpWatchStatus forKey:@"status"];
    }
    else {
        //Set Title State to currently watching
        tmpWatchStatus = @"current";
        // Still Watching
        [attributes setValue:tmpWatchStatus forKey:@"status"];
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
    [request addFormData:tmpd forKey:@"data"];
    // Do Update
    [request startJSONFormRequest:EasyNSURLConnectionvndapiJsonType];
    // Set correcting status to off
    self.correcting = false;
    long statuscode = [request getStatusCode];
    switch (statuscode) {
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
                NSError * jerror;
                NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&jerror];
                d = d[@"data"];
                self.EntryID = d[@"id"];
            }
            if (self.confirmed) { // Will only store actual title if confirmation feature is not turned on
                // Store Actual Title
                NSDictionary * titles = self.LastScrobbledInfo[@"titles"];
                self.LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",titles[@"en_jp"]];
            }
            self.confirmed = true;
            if (self.LastScrobbledTitleNew) {
                return ScrobblerAddTitleSuccessful;
            }
            // Update Successful
            return ScrobblerUpdateSuccessful;
        default:
            // Update Unsuccessful
            NSLog(@"Update failed: %@", [request getResponseDataString]);
            if (self.LastScrobbledTitleNew) {
                return ScrobblerAddTitleFailed;
            }
            return ScrobblerUpdateFailed;
    }
}
- (BOOL)updatestatus:(NSString *)titleid
            episode:(NSString *)episode
              score:(int)showscore
        watchstatus:(NSString*)showwatchstatus
              notes:(NSString*)note
          isPrivate:(BOOL)privatevalue
{
    NSLog(@"Updating Status for %@", titleid);
    // Update the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries/%@", self.EntryID]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set OAuth Token
    request.headers = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", [self getFirstAccount].accessToken]};
    //generate json
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    NSMutableDictionary * tmpd = [NSMutableDictionary new];
    [request setPostMethod:@"PATCH"];
    [tmpd setValue:self.EntryID forKey:@"id"];
    [tmpd setValue:@"libraryEntries" forKey:@"type"];
    //Set current episode
    if (episode.intValue != self.DetectedCurrentEpisode) {
        [attributes setValue:episode forKey:@"progress"];
    }
    //Set new watch status
    [attributes setValue:showwatchstatus forKey:@"status"];
    //Set new score.
    if (showscore > 0) {
        [attributes setValue:[NSString stringWithFormat:@"%i", showscore] forKey:@"ratingTwenty"];
        [attributes setValue:[NSNull null] forKey:@"rating"];
    }
    else {
        [attributes setValue:[NSNull null] forKey:@"ratingTwenty"];
        [attributes setValue:[NSNull null] forKey:@"rating"];
    }
    //Set new note
    [attributes setValue:note forKey:@"notes"];
    //Privacy
    if (privatevalue)
        [attributes setValue:@"true" forKey:@"private"];
    else
        [attributes setValue:@"false" forKey:@"private"];
    // Assemble JSON
    [tmpd setValue:attributes forKey:@"attributes"];
    [request addFormData:tmpd forKey:@"data"];
    // Do Update
    [request startJSONFormRequest:EasyNSURLConnectionvndapiJsonType];
    switch ([request getStatusCode]) {
        case 200:
        case 201:
            //Set New Values
            self.TitleScore = showscore;
            self.WatchStatus = showwatchstatus;
            self.TitleNotes = note;
            self.isPrivate = privatevalue;
            self.LastScrobbledEpisode = episode;
            self.DetectedCurrentEpisode = episode.intValue;
            return true;
        default:
            // Update Unsuccessful
            NSLog(@"Update failed: %@", [request getResponseDataString]);
            return false;
            break;
    }
    return false;
}
- (BOOL)stopRewatching:(NSString *)titleid {
    NSLog(@"Reverting rewatch for %@", titleid);
    // Update the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries/%@", self.EntryID]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set OAuth Token
    request.headers = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", [self getFirstAccount].accessToken]};
    //generate json
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    NSMutableDictionary * tmpd = [NSMutableDictionary new];
    [request setPostMethod:@"PATCH"];
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
    [request addFormData:tmpd forKey:@"data"];
    // Do Update
    [request startJSONFormRequest:EasyNSURLConnectionvndapiJsonType];
    switch ([request getStatusCode]) {
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
- (bool)removetitle:(NSString *)titleid {
    NSLog(@"Removing %@", titleid);
    // Update the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries/%@", self.EntryID]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set OAuth Token
    request.headers = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", [self getFirstAccount].accessToken]};
    [request setPostMethod:@"DELETE"];
        // Do Update
    [request startFormRequest];
    switch ([request getStatusCode]) {
        case 204:
            return true;
        default:
            // Update Unsuccessful
            NSLog(@"Delete failed: %@", [request getResponseDataString]);
            return false;
    }
    return false;
}
- (void)storeLastScrobbled {
    self.LastScrobbledTitle = self.DetectedTitle;
    self.LastScrobbledEpisode = self.DetectedEpisode;
    self.LastScrobbledSource = self.DetectedSource;
    self.slug = self.LastScrobbledInfo[@"slug"];
    NSDictionary * titles = self.LastScrobbledInfo[@"titles"];
    self.LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",titles[@"en_jp"]];
}
@end
