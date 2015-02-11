//
//  Hachidori+Hachidori_UserStatus.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//
//

#import "Hachidori+Hachidori_UserStatus.h"
#import "EasyNSURLConnection.h"

@implementation Hachidori (Hachidori_UserStatus)
-(BOOL)checkstatus:(NSString *)titleid {
    NSLog(@"Checking %@", titleid);
    // Update the title
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/libraries/%@", titleid]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Token
    [request addFormData:[NSString stringWithFormat:@"%@",[defaults objectForKey:@"Token"]] forKey:@"auth_token"];
    // Get Information
    [request startFormRequest];
    NSDictionary * d;
    int statusCode = [request getStatusCode];
    NSError * error = [request getError];
    if (statusCode == 200 || statusCode == 201 ) {
        online = true;
        //return Data
        NSError * error;
        d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&error];
        if ([d count] > 0) {
            NSLog(@"Title on list");
            [self populateStatusData:d];
        }
        else{
            NSLog(@"Title not on list");
            WatchStatus = @"currently-watching";
            LastScrobbledInfo = [self retrieveAnimeInfo:AniID];
            DetectedCurrentEpisode = @"0";
            TitleScore  = @"0";
            isPrivate = [defaults boolForKey:@"setprivate"];
            TitleNotes = @"";
            LastScrobbledTitleNew = true;
        }
        if ([LastScrobbledInfo objectForKey:@"episode_count"] == [NSNull null]) { // To prevent the scrobbler from failing because there is no episode total.
            TotalEpisodes = @"0"; // No Episode Total, Set to 0.
        }
        else { // Episode Total Exists
            TotalEpisodes = [LastScrobbledInfo  objectForKey:@"episode_count"];
        }
        // New Update Confirmation
        if (([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && LastScrobbledTitleNew && !correcting)|| ([[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !LastScrobbledTitleNew && !correcting)) {
            // Manually confirm updates
            confirmed = false;
        }
        else{
            // Automatically confirm updates
            confirmed = true;
        }
        return YES;
    }
    else if (error !=nil){
        if (error.code == NSURLErrorNotConnectedToInternet) {
            online = false;
            return NO;
        }
        else {
            online = true;
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
-(NSDictionary *)retrieveAnimeInfo:(NSString *)slug{
    NSLog(@"Getting Additional Info");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/anime/%@", slug]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Get Information
    [request startRequest];
    // Get Status Code
    int statusCode = [request getStatusCode];
    if (statusCode == 200) {
        NSError* error;
        NSDictionary * d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&error];
        return d;
    }
    else{
        NSDictionary * d = [[NSDictionary alloc] init];
        return d;
    }
}
-(void)populateStatusData:(NSDictionary *)d{
    // Info is there.
    NSDictionary * tmpinfo = [d objectForKey:@"anime"];
    WatchStatus = [d objectForKey:@"status"];
    //Get Notes;
    if ([d objectForKey:@"notes"] == [NSNull null]) {
        TitleNotes = @"";
    }
    else {
        TitleNotes = [d objectForKey:@"notes"];
    }
    // Get Rating
    NSDictionary * rating = [d objectForKey:@"rating"];
    if ([rating objectForKey:@"value"] == [NSNull null]){
        // Score is null, set to 0
        TitleScore = @"0";
    }
    else {
        TitleScore = [rating objectForKey:@"value"];
    }
    // Privacy Settings
    isPrivate = [[d objectForKey:@"private"] boolValue];
    DetectedCurrentEpisode = [d objectForKey:@"episodes_watched"];
    LastScrobbledInfo = tmpinfo;
    LastScrobbledTitleNew = false;
}
@end
