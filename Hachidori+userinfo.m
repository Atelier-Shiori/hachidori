//
//  Hachidori+userinfo.m
//  Hachidori
//
//  Created by 天々座理世 on 2018/05/28.
//

#import "Hachidori+userinfo.h"
#import "AniListConstants.h"
#import <AFNetworking/AFNetworking.h>

@implementation Hachidori (userinfo)
- (void)savekitsuinfo {
    // Retrieves missing user information and populates it before showing the UI.
    AFOAuthCredential *cred = [Hachidori getFirstAccount:0];
    if (cred && cred.expired) {
        [self refreshtokenWithService:0 successHandler:^(bool success) {
            if (success) {
                [self savekitsuinfo];
            }
        }];
        return;
    }
    if (cred) {
        [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    NSError *error;
    id responseObject = [self.syncmanager syncGET:@"https://kitsu.io/api/edge/users?filter[self]=true&fields[users]=name,slug,avatar,ratingSystem" parameters:@{} task:NULL error:&error];
    if (!error) {
        if (((NSArray *)responseObject[@"data"]).count > 0) {
            NSDictionary *d = [NSArray arrayWithArray:responseObject[@"data"]][0];
            NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
            [defaults setValue:d[@"id"] forKey:@"UserID"];
            if (d[@"attributes"][@"name"] != [NSNull null]) {
                [defaults setValue:d[@"attributes"][@"name"] forKey:@"loggedinusername"];
            }
            else if (d[@"attributes"][@"slug"] != [NSNull null]) {
                [defaults setValue:d[@"attributes"][@"slug"] forKey:@"loggedinusername"];
            }
            else {
                [defaults setValue:@"Unknown User" forKey:@"loggedinusername"];
            }
        }
        else {
            // Remove Account, invalid token
            [AFOAuthCredential deleteCredentialWithIdentifier:@"Hachidori"];
        }
    }
    else {
        // Remove Account
        [AFOAuthCredential deleteCredentialWithIdentifier:@"Hachidori"];
    }
}

- (void)saveanilistuserinfo {
    // Retrieves missing user information and populates it before showing the UI.
    AFOAuthCredential *cred = [Hachidori getFirstAccount:1];
    if (cred && cred.expired) {
        return;
    }
    if (cred) {
        [self.syncmanager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    NSError *error;
    
    id responseObject = [self.syncmanager syncPOST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistCurrentUsernametoUserId, @"variables" : @{}} task:NULL error:&error];
    if (!error) {
        if (responseObject[@"data"][@"Viewer"] != [NSNull null]) {
            NSDictionary *d = responseObject[@"data"][@"Viewer"];
            NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
            [defaults setValue:d[@"id"] forKey:@"UserID-anilist"];
            [defaults setValue:d[@"name"] forKey:@"loggedinusername-anilist"];
        }
        else {
            // Remove Account, invalid token
            [AFOAuthCredential deleteCredentialWithIdentifier:@"Hachidori - AniList"];
        }
    }
    else {
        // Remove Account
        [AFOAuthCredential deleteCredentialWithIdentifier:@"Hachidori - AniList"];
    }
}

- (void)checkaccountinformation {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([Hachidori getFirstAccount:0]) {
        bool refreshKitsu = (![defaults valueForKey:@"kitsu-userinformationrefresh"] || ((NSDate *)[defaults objectForKey:@"kitsu-userinformationrefresh"]).timeIntervalSinceNow < 0);
        if ((![defaults valueForKey:@"loggedinusername"] && ![defaults valueForKey:@"UserID"]) || ((NSString *)[defaults valueForKey:@"loggedinusername"]).length == 0 || refreshKitsu) {
            [self savekitsuinfo];
            [NSUserDefaults.standardUserDefaults setObject:[NSDate dateWithTimeIntervalSinceNow:259200] forKey:@"kitsu-userinformationrefresh"];
        }
    }
    if ([Hachidori getFirstAccount:2]) {
        bool refreshAniList = (![defaults valueForKey:@"anilist-userinformationrefresh"] || ((NSDate *)[defaults objectForKey:@"anilist-userinformationrefresh"]).timeIntervalSinceNow < 0);
        if ((![defaults valueForKey:@"loggedinusername-anilist"] || ![defaults valueForKey:@"UserID-anilist"]) || ((NSString *)[defaults valueForKey:@"loggedinusername-anilist"]).length == 0 || refreshAniList) {
            [self saveanilistuserinfo];
            [NSUserDefaults.standardUserDefaults setObject:[NSDate dateWithTimeIntervalSinceNow:259200] forKey:@"anilist-userinformationrefresh"];
        }
    }
}

- (bool)hasUserInfoCurrentService {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    switch ([Hachidori currentService]) {
        case serviceKitsu:
            return ([defaults valueForKey:@"loggedinusername"] && [defaults valueForKey:@"UserID"]);
        case serviceAniList:
            return ([defaults valueForKey:@"loggedinusername-anilist"] && [defaults valueForKey:@"UserID-anilist"]);
    }
    return NO;
}
@end
