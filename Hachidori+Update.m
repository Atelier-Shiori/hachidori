//
//  Hachidori+Update.m
//  Hachidori
//
//  Created by 高町なのは on 2015/02/11.
//  Copyright 2009-2018 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+Update.h"
#import <AFNetworking/AFNetworking.h>

@implementation Hachidori (Update)
- (int)updatetitle:(NSString *)titleid {
    if (!titleid || titleid.length == 0) {
        NSLog(@"Internal Error. Title: %@, Episode: %@", self.detectedscrobble.DetectedTitle, self.detectedscrobble.DetectedEpisode);
        return ScrobblerFailed;
    }
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
        [self storeLastScrobbled];
        return ScrobblerConfirmNeeded;
    }
    if (self.detectedscrobble.DetectedEpisode.intValue <= self.detectedscrobble.DetectedCurrentEpisode && (![self.detectedscrobble.WatchStatus isEqualToString:@"completed"] || ![[NSUserDefaults standardUserDefaults] boolForKey:@"RewatchEnabled"])) {
        // Already Watched, no need to scrobble
        // Store Scrobbled Title and Episode
        [self storeLastScrobbled];
        [self sendDiscordPresence:self.lastscrobble];
        self.detectedscrobble.confirmed = true;
        [self multiscrobbleWithType:self.correcting ? MultiScrobbleTypeCorrection : MultiScrobbleTypeScrobble withTitleID:titleid];
        return ScrobblerUpdateNotNeeded;
    }
    else if (self.detectedscrobble.DetectedEpisode.intValue == self.detectedscrobble.DetectedCurrentEpisode && self.detectedscrobble.DetectedCurrentEpisode == self.detectedscrobble.TotalEpisodes && self.detectedscrobble.TotalEpisodes > 1 && [self.detectedscrobble.WatchStatus isEqualToString:@"completed"]) {
       //Do not set rewatch status for current episode equal to total episodes.
        [self storeLastScrobbled];
        [self sendDiscordPresence:self.lastscrobble];
        self.detectedscrobble.confirmed = true;
        [self multiscrobbleWithType:self.correcting ? MultiScrobbleTypeCorrection : MultiScrobbleTypeScrobble withTitleID:titleid];
        return ScrobblerUpdateNotNeeded;
    }
    else if (!self.detectedscrobble.LastScrobbledTitleNew && [[NSUserDefaults standardUserDefaults] boolForKey:@"ConfirmUpdates"] && !self.detectedscrobble.confirmed && !self.correcting) {
        // Confirm before updating title
        [self storeLastScrobbled];
        return ScrobblerConfirmNeeded;
    }
    else {
        int status = [self performupdate:titleid withService:(int)[Hachidori currentService]];
        if (status == ScrobblerAddTitleSuccessful || status == ScrobblerUpdateSuccessful) {
            [self multiscrobbleWithType:self.correcting ? MultiScrobbleTypeCorrection : MultiScrobbleTypeScrobble withTitleID:titleid];
        }
        return status;
    }
}
- (int)performupdate:(NSString *)titleid withService:(long)service {
    int status;
    switch (service) {
        case 0:
            status = [self.kitsumanager kitsuperformupdate:titleid];
            break;
        case 1:
            status = [self.anilistmanager anilistperformupdate:titleid];
            break;
        case 2:
            status = [self.malmanger malperformupdate:titleid];
            break;
        default:
            return ScrobblerFailed;
    }
    if (service == [Hachidori currentService]) {
        switch (status) {
            case ScrobblerAddTitleSuccessful:
                //[self.twittermanager postaddanimetweet:self.lastscrobble];
                break;
            case ScrobblerUpdateSuccessful:
                //[self.twittermanager postupdateanimetweet:self.lastscrobble];
                break;
            default:
                break;
        }
        [self sendDiscordPresence:self.lastscrobble];
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
            [self.kitsumanager kitsuupdatestatus:titleid episode:episode score:showscore watchstatus:showwatchstatus notes:note isPrivate:privatevalue completion:completionhandler];
            break;
        case 1:
            [self.anilistmanager anilistupdatestatus:titleid episode:episode score:showscore watchstatus:showwatchstatus notes:note isPrivate:privatevalue completion:completionhandler];
            break;
        case 2:
            [self.malmanger malupdatestatus:titleid episode:episode score:showscore watchstatus:showwatchstatus notes:note completion:completionhandler];
        default:
            completionhandler(false);
            break;
    }
}
- (BOOL)stopRewatching:(NSString *)titleid withService:(long)service {
    int status;
    switch (service) {
        case 0:
            status = [self.kitsumanager kitsustopRewatching:titleid];
            break;
        case 1:
            status = [self.anilistmanager aniliststopRewatching:titleid];
            break;
        case 2:
            status = [self.malmanger malstopRewatching:titleid];
            break;
        default:
            return ScrobblerFailed;
    }
    if (status == 1) {
        [self multiscrobbleWithType:MultiScrobbleTypeRevertRewatch withTitleID:titleid];
    }
    if (service == [Hachidori currentService]) {
        [self sendDiscordPresence:self.lastscrobble];
    }
    return status;
}
- (bool)removetitle:(NSString *)titleid withService:(long)service {
    switch (service) {
        case 0:
            return [self.kitsumanager kitsuremovetitle:titleid];
        case 1:
            return [self.anilistmanager anilistremovetitle:titleid];
        case 2:
            return [self.malmanger malremovetitle:titleid];
        default:
            return NO;
    }
}
- (void)storeLastScrobbled {
    switch ([Hachidori currentService]) {
        case 0:
            [self.kitsumanager kitsustoreLastScrobbled];
            break;
        case 1:
            [self.anilistmanager aniliststoreLastScrobbled];
            break;
        case 2:
            [self.malmanger malstoreLastScrobbled];
            break;
        default:
            break;
    }
}
@end
