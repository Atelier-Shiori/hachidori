//
//  Hachidori+Update.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2018 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+Update.h"
#import "Hachidori+KitsuUpdate.h"
#import "Hachidori+AniListUpdate.h"
#import <AFNetworking/AFNetworking.h>

@implementation Hachidori (Update)
- (int)updatetitle:(NSString *)titleid {
    if (!self.detectedscrobble.airing && !self.detectedscrobble.completedairing) {
        // User attempting to update title that haven't been aired.
        return ScrobblerInvalidScrobble;
    }
    else if ((self.detectedscrobble.DetectedEpisode).intValue == self.detectedscrobble.TotalEpisodes && self.detectedscrobble.airing && !self.detectedscrobble.completedairing) {
        // User attempting to complete a title, which haven't finished airing
        return ScrobblerInvalidScrobble;
    }
    NSLog(@"Updating Title");
    if (self.detectedscrobble.LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmNewTitle"] && !self.detectedscrobble.confirmed && !self.correcting) {
        // Confirm before updating title
        //[self storeLastScrobbled];
        return ScrobblerConfirmNeeded;
    }
    if (self.detectedscrobble.DetectedEpisode.intValue <= self.detectedscrobble.DetectedCurrentEpisode && (![self.detectedscrobble.WatchStatus isEqualToString:@"completed"] || ![[NSUserDefaults standardUserDefaults] boolForKey:@"RewatchEnabled"])) {
        // Already Watched, no need to scrobble
        // Store Scrobbled Title and Episode
        [self storeLastScrobbled];
        [self sendDiscordPresence];
        self.detectedscrobble.confirmed = true;
        return ScrobblerUpdateNotNeeded;
    }
    else if (self.detectedscrobble.DetectedEpisode.intValue == self.detectedscrobble.DetectedCurrentEpisode && self.detectedscrobble.DetectedCurrentEpisode == self.detectedscrobble.TotalEpisodes && self.detectedscrobble.TotalEpisodes > 1 && [self.detectedscrobble.WatchStatus isEqualToString:@"completed"]) {
       //Do not set rewatch status for current episode equal to total episodes.
        [self storeLastScrobbled];
        [self sendDiscordPresence];
        self.detectedscrobble.confirmed = true;
        return ScrobblerUpdateNotNeeded;
    }
    else if (!self.detectedscrobble.LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !self.detectedscrobble.confirmed && !self.correcting) {
        // Confirm before updating title
        [self storeLastScrobbled];
        return ScrobblerConfirmNeeded;
    }
    else {
        int status = [self performupdate:titleid withService:[Hachidori currentService]];
        if (status == ScrobblerAddTitleSuccessful || status == ScrobblerUpdateSuccessful) {
            
        }
        return status;
    }
}
- (int)performupdate:(NSString *)titleid withService:(long)service{
    int status;
    switch (service) {
        case 0:
            status = [self kitsuperformupdate:titleid];
            break;
        case 1:
            status = [self anilistperformupdate:titleid];
            break;
        default:
            return ScrobblerFailed;
    }
    if (service == [Hachidori currentService]) {
        switch (status) {
            case ScrobblerAddTitleSuccessful:
                [self.twittermanager postaddanimetweet:self.lastscrobble];
                break;
            case ScrobblerUpdateSuccessful:
                [self.twittermanager postupdateanimetweet:self.lastscrobble];
                break;
            default:
                break;
        }
        [self sendDiscordPresence];
    }
    return status;
}
- (void)updatestatus:(NSString *)titleid
            episode:(NSString *)episode
              score:(int)showscore
        watchstatus:(NSString*)showwatchstatus
              notes:(NSString*)note
          isPrivate:(BOOL)privatevalue
          completion:(void (^)(bool success))completionhandler
         withService:(long)service
{
    switch (service) {
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
- (BOOL)stopRewatching:(NSString *)titleid withService:(long)service {
    int status;
    switch (service) {
        case 0:
            status = [self kitsustopRewatching:titleid];
            break;
        case 1:
            status = [self aniliststopRewatching:titleid];
            break;
        default:
            return ScrobblerFailed;
    }
    if (service == [Hachidori currentService]) {
        [self sendDiscordPresence];
    }
    return status;
}
- (bool)removetitle:(NSString *)titleid withService:(long)service {
    switch (service) {
        case 0:
            return [self kitsuremovetitle:titleid];
        case 1:
            return [self anilistremovetitle:titleid];
        default:
            return NO;
    }
}
- (void)storeLastScrobbled {
    switch ([Hachidori currentService]) {
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
