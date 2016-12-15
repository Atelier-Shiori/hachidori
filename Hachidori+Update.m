//
//  Hachidori+Update.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+Update.h"
#import "EasyNSURLConnection.h"

@implementation Hachidori (Update)
-(int)updatetitle:(NSString *)titleid {
    NSLog(@"Updating Title");
    if (LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && !confirmed && !correcting) {
        // Confirm before updating title
        [self storeLastScrobbled];
        return 3;
    }
    if ([DetectedEpisode intValue] <= DetectedCurrentEpisode && (![WatchStatus isEqualToString:@"completed"] || ![[NSUserDefaults standardUserDefaults] boolForKey:@"RewatchEnabled"])) {
        // Already Watched, no need to scrobble
        // Store Scrobbled Title and Episode
        [self storeLastScrobbled];
        confirmed = true;
        return 2;
    }
    else if ([DetectedEpisode intValue] == DetectedCurrentEpisode && DetectedCurrentEpisode == TotalEpisodes && TotalEpisodes > 1 && [WatchStatus isEqualToString:@"completed"]){
       //Do not set rewatch status for current episode equal to total episodes.
        [self storeLastScrobbled];
        confirmed = true;
        return 2;
    }
    else if (!LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !confirmed && !correcting) {
        // Confirm before updating title
        [self storeLastScrobbled];
        return 3;
    }
    else {
        return [self performupdate:titleid];
    }
}
-(int)performupdate:(NSString *)titleid{
    // Update the title
    //Set library/scrobble API
    NSString * updatemethod;
    if (EntryID){
        //Set URL to update existing entry
        updatemethod = [NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries/%@", EntryID];
    }
    else{
        //Create new entry
        //Set URL to update existing entry
        updatemethod = @"https://kitsu.io/api/edge/library-entries/";
    }
    NSURL *url = [NSURL URLWithString:updatemethod];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
        //Set Status
    BOOL tmprewatching;
    long tmprewatchedcount;
    NSString * tmpWatchStatus;
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    NSMutableDictionary * tmpd = [NSMutableDictionary new];
    if (EntryID){
        [request setPostMethod:@"PATCH"];
        [tmpd setValue:EntryID forKey:@"id"];
    }
    else{
        [request setPostMethod:@"POST"];
    }
    [tmpd setValue:@"libraryEntries" forKey:@"type"];
        [attributes setValue:DetectedEpisode forKey:@"progress"];
    if([DetectedEpisode intValue] == TotalEpisodes) {
        //Set Title State
        tmpWatchStatus = @"completed";
        // Since Detected Episode = Total Episode, set the status as "Complete"
        [attributes setValue:tmpWatchStatus forKey:@"status"];
        //Set rewatch status to false
        tmprewatching = false;
        if (rewatching){
            // Increment rewatch count
            tmprewatchedcount = rewatchcount + 1;
            [attributes setValue:[[NSNumber numberWithLong:tmprewatchedcount] stringValue] forKey:@"reconsumeCount"];
        }
        else if ([DetectedEpisode intValue] == DetectedCurrentEpisode && DetectedCurrentEpisode == TotalEpisodes){
            //Increment Rewatch Count only
            tmprewatchedcount = rewatchcount + 1;
            [attributes setValue:[[NSNumber numberWithLong:tmprewatchedcount] stringValue] forKey:@"reconsumeCount"];
        }
    }
    else if ([WatchStatus isEqualToString:@"completed"] && [DetectedEpisode intValue] < TotalEpisodes){
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
        tmprewatching = rewatching;
    }
    // Set rewatch status in form data
    if (tmprewatching) {
        [attributes setValue:@"true" forKey:@"reconsuming"];
    }
    else{
        [attributes setValue:@"false" forKey:@"reconsuming"];
    }
    // Set existing score to prevent the score from being erased.
    if (TitleScore > 0){
        [attributes setValue:@(TitleScore) forKey:@"rating"];
    }
    //Privacy
    if (isPrivate)
        [attributes setValue:@"true" forKey:@"private"];
    else
        [attributes setValue:@"false" forKey:@"private"];
    
    // Assemble JSON
    [tmpd setValue:attributes forKey:@"attributes"];
    [request addFormData:tmpd forKey:@"data"];
    // Do Update
    [request startJSONFormRequest];
    // Set correcting status to off
    correcting = false;
    long statuscode = [request getStatusCode];
    NSLog(@"%@",[request getResponseDataString]);
    switch (statuscode) {
        case 201:
        case 200:
            // Store Scrobbled Title and Episode
            LastScrobbledTitle = DetectedTitle;
            LastScrobbledEpisode = DetectedEpisode;
            DetectedCurrentEpisode = [LastScrobbledEpisode intValue];
            LastScrobbledSource = DetectedSource;
            rewatching = tmprewatching;
            WatchStatus = tmpWatchStatus;
            if (!EntryID){
                // Retrieve new entry id
                NSError * jerror;
                NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&jerror];
                d = d[@"data"];
                EntryID = d[@"id"];
            }
            if (confirmed) { // Will only store actual title if confirmation feature is not turned on
                // Store Actual Title
                NSDictionary * titles = LastScrobbledInfo[@"titles"];
                LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",titles[@"en_jp"]];
            }
            confirmed = true;
            if (LastScrobbledTitleNew) {
                return 21;
            }
            // Update Successful
            return 22;
        default:
            // Update Unsuccessful
            if (LastScrobbledTitleNew) {
                return 52;
            }
            return 53;
    }
}
-(BOOL)updatestatus:(NSString *)titleid
            episode:(NSString *)episode
              score:(float)showscore
        watchstatus:(NSString*)showwatchstatus
              notes:(NSString*)note
          isPrivate:(BOOL)privatevalue
{
    NSLog(@"Updating Status for %@", titleid);
    // Update the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/libraries/%@",  titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set current episode
    if ([episode intValue] != DetectedCurrentEpisode) {
        [request addFormData:episode forKey:@"episodes_watched"];
    }
    //Set new watch status
    [request addFormData:showwatchstatus forKey:@"status"];
    //Set new score.
    [request addFormData:[NSString stringWithFormat:@"%f", showscore] forKey:@"rating"];
    //Set new note
    [request addFormData:note forKey:@"notes"];
    //Privacy
    if (privatevalue)
        [request addFormData:@"private" forKey:@"privacy"];
    else
        [request addFormData:@"public" forKey:@"privacy"];
    // Do Update
    [request startFormRequest];
    switch ([request getStatusCode]) {
        case 200:
        case 201:
            //Set New Values
            TitleScore = showscore;
            WatchStatus = showwatchstatus;
            TitleNotes = note;
            isPrivate = privatevalue;
            LastScrobbledEpisode = episode;
            DetectedCurrentEpisode = [episode intValue];
            return true;
        default:
            // Update Unsuccessful
            return false;
            break;
    }
    return false;
}
-(BOOL)stopRewatching:(NSString *)titleid{
    NSLog(@"Reverting rewatch for %@", titleid);
    // Update the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/libraries/%@",  titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set current episode to total episodes
    [request addFormData:[[NSNumber numberWithInt:TotalEpisodes] stringValue] forKey:@"episodes_watched"];
    //Revert watch status to complete
    [request addFormData:@"completed" forKey:@"status"];
    //Set Rewatch status to false
    [request addFormData:@"false" forKey:@"rewatching"];
    
    // Do Update
    [request startFormRequest];
    switch ([request getStatusCode]) {
        case 200:
        case 201:
            //Set New Values
            rewatching = false;
            WatchStatus = @"completed";
            LastScrobbledEpisode = [[NSNumber numberWithInt:TotalEpisodes] stringValue];
            DetectedCurrentEpisode = TotalEpisodes;
            return true;
        default:
            // Rewatch revert unsuccessful
            return false;
            break;
    }
    return false;

}
-(bool)removetitle:(NSString *)titleid{
    NSLog(@"Removing %@", titleid);
    // Update the title
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/library-entries/%@", EntryID]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    [request setPostMethod:@"DELETE"];
        // Do Update
    [request startFormRequest];
    switch ([request getStatusCode]) {
        case 204:
            return true;
        default:
            // Update Unsuccessful
            return false;
    }
    return false;
}
-(void)storeLastScrobbled{
    LastScrobbledTitle = DetectedTitle;
    LastScrobbledEpisode = DetectedEpisode;
    LastScrobbledSource = DetectedSource;
    NSDictionary * titles = LastScrobbledInfo[@"titles"];
    LastScrobbledActualTitle = [NSString stringWithFormat:@"%@",titles[@"en_jp"]];
}
@end
