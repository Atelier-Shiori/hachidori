//
//  Hachidori+Update.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2018 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+Update.h"
#import "Hachidori+KitsuUpdate.h"
#import "Hachidori+AniListUpdate.h"
#import "Hachidori+Twitter.h"
#import "Hachidori+Discord.h"
#import <AFNetworking/AFNetworking.h>

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
        [self sendDiscordPresence];
        self.confirmed = true;
        return ScrobblerUpdateNotNeeded;
    }
    else if (self.DetectedEpisode.intValue == self.DetectedCurrentEpisode && self.DetectedCurrentEpisode == self.TotalEpisodes && self.TotalEpisodes > 1 && [self.WatchStatus isEqualToString:@"completed"]) {
       //Do not set rewatch status for current episode equal to total episodes.
        [self storeLastScrobbled];
        [self sendDiscordPresence];
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
    int status;
    switch (self.currentService) {
        case 0:
            status = [self kitsuperformupdate:titleid];
            break;
        case 1:
            status = [self anilistperformupdate:titleid];
            break;
        default:
            return ScrobblerFailed;
    }
    switch (status) {
        case ScrobblerAddTitleSuccessful:
            [self postaddanimetweet];
            break;
        case ScrobblerUpdateSuccessful:
            [self postupdateanimetweet];
            break;
        default:
            break;
    }
    [self sendDiscordPresence];
    return status;
}
- (void)updatestatus:(NSString *)titleid
            episode:(NSString *)episode
              score:(int)showscore
        watchstatus:(NSString*)showwatchstatus
              notes:(NSString*)note
          isPrivate:(BOOL)privatevalue
          completion:(void (^)(bool success))completionhandler
{
    switch (self.currentService) {
        case 0:
            [self kitsuupdatestatus:titleid episode:episode score:showscore watchstatus:showwatchstatus notes:note isPrivate:privatevalue completion:completionhandler];
            break;
        case 1:
            [self anilistupdatestatus:titleid episode:episode score:showscore watchstatus:showwatchstatus notes:note isPrivate:privatevalue completion:completionhandler];
            break;
        default:
            completionhandler(false);
            break;
    }
}
- (BOOL)stopRewatching:(NSString *)titleid {
    int status;
    switch (self.currentService) {
        case 0:
            status = [self kitsustopRewatching:titleid];
            break;
        case 1:
            status = [self aniliststopRewatching:titleid];
            break;
        default:
            return ScrobblerFailed;
    }
    [self sendDiscordPresence];
    return status;
}
- (bool)removetitle:(NSString *)titleid {
    switch (self.currentService) {
        case 0:
            return [self kitsuremovetitle:titleid];
        case 1:
            return [self anilistremovetitle:titleid];
        default:
            return NO;
    }
}
- (void)storeLastScrobbled {
    switch (self.currentService) {
        case 0:
            [self kitsustoreLastScrobbled];
            break;
        case 1:
            [self aniliststoreLastScrobbled];
            break;
        default:
            break;
    }
}
@end
