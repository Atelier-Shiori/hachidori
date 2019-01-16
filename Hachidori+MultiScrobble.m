//
//  Hachidori+MultiScrobble.m
//  Hachidori
//
//  Created by 香風智乃 on 1/14/19.
//

#import "Hachidori+MultiScrobble.h"
#import "Hachidori+UserStatus.h"
#import "Hachidori+Update.h"
#import <AFNetworking/AFNetworking.h>
#import "ScoreConversion.h"

@implementation Hachidori (MultiScrobble)
- (void)multiscrobbleWithType:(MultiScrobbleType)scrobbletype withTitleID:(NSString *)titleid {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults boolForKey:@"multiscrobbleenabled"]) {
        NSDictionary *mapping = [self lookupmappings:titleid];
        switch (scrobbletype) {
            case MultiScrobbleTypeScrobble:
            case MultiScrobbleTypeCorrection:
                [self performMultiScrobbleScrobbleWithMapping:mapping withScrobbleType:scrobbletype];
                break;
            case MultiScrobbleTypeEntryupdate:
                [self performMultiScrobbleEntryUpdateWithMapping:mapping];
                break;
            default:
                break;
        }
    }
}

- (void)performMultiScrobbleScrobbleWithMapping:(NSDictionary *)mapping withScrobbleType:(MultiScrobbleType)type {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (type == MultiScrobbleTypeCorrection && self.correcting && ![defaults boolForKey:@"multiscrobblescorrectionsenabled"]) {
        return;
    }
    else if (type == MultiScrobbleTypeScrobble && !self.correcting && ![defaults boolForKey:@"multiscrobblescrobblesenabled"]) {
        return;
    }
    // Perform MultiScrobble Scrobble
    if ([defaults boolForKey:@"multiscrobblekitsuenabled"] && [Hachidori currentService] != 0) {
        if ([Hachidori getFirstAccount:0]) {
            if (mapping[@"kitsu_id"] != [NSNull null] && ((NSNumber *)mapping[@"kitsu_id"]).intValue > 0) {
                // Obtain Entry
                self.kitsumanager.detectedscrobble = self.detectedscrobble.copy;
                self.kitsumanager.detectedscrobble.AniID = ((NSNumber *)mapping[@"kitsu_id"]).stringValue;
                if ([self checkstatus:self.kitsumanager.detectedscrobble.AniID withService:0]) {
                    if ([self shouldMultiScrobble:self.kitsumanager.detectedscrobble]) {
                        int status = [self performupdate:self.kitsumanager.detectedscrobble.AniID withService:0];
                        switch (status) {
                            case 21:
                            case 22:
                                [NSNotificationCenter.defaultCenter postNotificationName:@"MultiScrobbleNotification" object:@{@"title" : @"MultiScrobble", @"message" : self.correcting ? @"Correction was successful on Kitsu" : @"Scrobble was successful on Kitsu", @"identifier" : @"multiscrobble-kitsu"}];
                                break;
                            default:
                                [NSNotificationCenter.defaultCenter postNotificationName:@"MultiScrobbleNotification" object:@{@"title" : @"MultiScrobble", @"message" : self.correcting ? @"Correction was not successful on Kitsu" : @"Scrobble was not successful on Kitsu", @"identifier" : @"multiscrobble-kitsu"}];
                                break;
                        }
                    }
                }
            }
        }
    }
    else if ([defaults boolForKey:@"multiscrobbleanilistenabled"] && [Hachidori currentService] != 1) {
        if ([Hachidori getFirstAccount:1]) {
            if (mapping[@"anilist_id"] != [NSNull null] && ((NSNumber *)mapping[@"anilist_id"]).intValue > 0) {
                // Obtain Entry
                self.anilistmanager.detectedscrobble = self.detectedscrobble.copy;
                self.anilistmanager.detectedscrobble.AniID = ((NSNumber *)mapping[@"anilist_id"]).stringValue;
                if ([self checkstatus:self.anilistmanager.detectedscrobble.AniID withService:1]) {
                    if ([self shouldMultiScrobble:self.anilistmanager.detectedscrobble]) {
                        int status = [self performupdate:self.anilistmanager.detectedscrobble.AniID withService:1];
                        switch (status) {
                            case 21:
                            case 22:
                                [NSNotificationCenter.defaultCenter postNotificationName:@"MultiScrobbleNotification" object:@{@"title" : @"MultiScrobble", @"message" : self.correcting ? @"Correction was successful on AniList" : @"Scrobble was successful on AniList", @"identifier" : @"multiscrobble-anilist"}];
                                break;
                            default:
                                [NSNotificationCenter.defaultCenter postNotificationName:@"MultiScrobbleNotification" object:@{@"title" : @"MultiScrobble", @"message" : self.correcting ? @"Correction was not successful on AniList" : @"Scrobble was not successful on AniList", @"identifier" : @"multiscrobble-anilist"}];
                                break;
                        }
                    }
                }
            }
        }
    }
}

- (void)performMultiScrobbleEntryUpdateWithMapping:(NSDictionary *)mapping  {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults boolForKey:@"multiscrobbleentryupdatesenabled"]) {
        // Perform entry update
        if ([defaults boolForKey:@"multiscrobblekitsuenabled"] && [Hachidori currentService] != 0) {
            if ([Hachidori getFirstAccount:0] && self.kitsumanager.lastscrobble) {
                if (mapping[@"kitsu_id"] != [NSNull null] && ((NSNumber *)mapping[@"kitsu_id"]).intValue > 0) {
                    int convertedscore;
                    switch ([Hachidori currentService]) {
                        case 1:
                            // Raw Score to Rating Twenty
                            convertedscore = [ScoreConversion translateadvancedKitsuRatingtoRatingTwenty:(int)(self.lastscrobble.TitleScore/10)];
                            break;
                    }
                    [self updatestatus:((NSNumber *)mapping[@"kitsu_id"]).stringValue episode:@(self.lastscrobble.DetectedCurrentEpisode).stringValue score:convertedscore watchstatus:self.lastscrobble.WatchStatus notes:self.lastscrobble.TitleNotes isPrivate:self.lastscrobble.isPrivate completion:^(bool success) {
                        [NSNotificationCenter.defaultCenter postNotificationName:@"MultiScrobbleNotification" object:@{@"title" : @"MultiScrobble", @"message" : success ? @"Entry Update on Kitsu is successful" : @"Entry Update had failed on Kitsu", @"identifier" : @"multiscrobble-kitsu"}];
                    } withService:0];
                }
            }
        }
        else if ([defaults boolForKey:@"multiscrobbleanilistenabled"] && [Hachidori currentService] != 1) {
            if ([Hachidori getFirstAccount:1] && self.anilistmanager.lastscrobble) {
                if (mapping[@"anilist_id"] != [NSNull null] && ((NSNumber *)mapping[@"anilist_id"]).intValue > 0) {
                    int convertedscore;
                    switch ([Hachidori currentService]) {
                        case 0:
                            // Rating Twenty to Raw Score
                            convertedscore = [ScoreConversion ratingTwentytoAdvancedScore:self.lastscrobble.TitleScore];
                            break;
                    }
                    [self updatestatus:((NSNumber *)mapping[@"anilist_id"]).stringValue episode:@(self.lastscrobble.DetectedCurrentEpisode).stringValue score:convertedscore watchstatus:self.lastscrobble.WatchStatus notes:self.lastscrobble.TitleNotes isPrivate:self.lastscrobble.isPrivate completion:^(bool success) {
                        [NSNotificationCenter.defaultCenter postNotificationName:@"MultiScrobbleNotification" object:@{@"title" : @"MultiScrobble", @"message" : success ? @"Entry Update on AniList is successful" : @"Entry Update had failed on AniList", @"identifier" : @"multiscrobble-anilist"}];
                    } withService:1];
                }
            }
        }
    }
}

- (NSDictionary *)lookupmappings:(NSString *)titleid {
    NSDictionary *mapping = [self retrieveExistingMappingAsDictionary:titleid];
    if (mapping) {
        return mapping;
    }
    return [self retrievemappings:titleid];
}

- (NSDictionary *)retrievemappings:(NSString *)titleid {
    NSString *site;
    switch ([Hachidori currentService]) {
        case 0:
            site = @"kitsu";
            break;
        case 1:
            site = @"anilist";
            break;
        default:
            return nil;
    }
    NSString *hatourl;
#ifdef oss
    hatourl = [NSString stringWithFormat:@"http://localhost:50420/api/mappings/%@/anime/%@", site, titleid];
#else
    hatourl = [NSString stringWithFormat:@"https://hato.malupdaterosx.moe/api/mappings/%@/anime/%@", site, titleid];
#endif
    NSURLSessionDataTask *task;
    NSError *error;
    [self.syncmanager.requestSerializer clearAuthorizationHeader];
    id responseObject = [self.syncmanager syncGET:hatourl parameters:nil task:&task error:&error];
    long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
    switch (statusCode) {
        case 200: {
            if (responseObject[@"data"] && responseObject[@"data"] != [NSNull null]) {
                [self saveTitleIDMappings:responseObject[@"data"] withTitleId:titleid];
                return [self retrieveExistingMappingAsDictionary:titleid];
            }
            else {
                return nil;
            }
            break;
        }
        case 404: {
            NSLog(@"Title mappings for %@ not found", titleid);
            return nil;
        }
        default: {
            NSLog(@"Title mappings lookup failed: %@", error.localizedDescription);
            return nil;
        }
    }
    return nil;
}

- (void)saveTitleIDMappings:(NSDictionary *)mapping withTitleId:(NSString *)titleid {
    NSManagedObject *map = [self retrieveExistingMapping:titleid];
    if (!map) {
        map = [NSEntityDescription insertNewObjectForEntityForName:@"Titleidmappings" inManagedObjectContext:self.managedObjectContext];
    }
    [map setValuesForKeysWithDictionary:mapping];
    [self.managedObjectContext save:nil];
}
- (NSDictionary *)retrieveExistingMappingAsDictionary:(NSString *)titleid {
    NSManagedObject *mapping = [self retrieveExistingMapping:titleid];
    if (mapping) {
        NSArray *keys = mapping.entity.attributesByName.allKeys;
        return [mapping dictionaryWithValuesForKeys:keys];
    }
    return nil;
}
- (NSManagedObject *)retrieveExistingMapping:(NSString *)titleid {
    __block NSArray *mappings = @[];
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Titleidmappings" inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate;
        switch ([Hachidori currentService]) {
            case 0:
                predicate = [NSPredicate predicateWithFormat:@"kitsu_id == %i", titleid.intValue];
                break;
            case 1:
                predicate = [NSPredicate predicateWithFormat:@"anilist_id == %i", titleid.intValue];
                break;
            default:
                break;
        }
        if (predicate) {
            fetchRequest.predicate = predicate;
            NSError *error = nil;
            mappings = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        }
    }];
    if (mappings.count > 0) {
        return mappings[0];
    }
    return nil;
}

- (bool)shouldMultiScrobble:(DetectedScrobbleStatus *)dstatus {
    // Checks if Hachidori should proceed with doing a multiscrobble.
    if (!dstatus.airing && !dstatus.completedairing) {
        // User attempting to update title that haven't been aired.
        return NO;
    }
    else if ((dstatus.DetectedEpisode).intValue == dstatus.TotalEpisodes && dstatus.airing && !dstatus.completedairing) {
        // User attempting to complete a title, which haven't finished airing
        return NO;
    }
    else if (dstatus.DetectedEpisode.intValue <= dstatus.DetectedCurrentEpisode && (![dstatus.WatchStatus isEqualToString:@"completed"] || ![[NSUserDefaults standardUserDefaults] boolForKey:@"RewatchEnabled"])) {
        return NO;
    }
    else if (dstatus.DetectedEpisode.intValue == dstatus.DetectedCurrentEpisode && dstatus.DetectedCurrentEpisode == dstatus.TotalEpisodes && dstatus.TotalEpisodes > 1 && [dstatus.WatchStatus isEqualToString:@"completed"]) {
        //Do not set rewatch status for current episode equal to total episodes.
        return NO;
    }
    return YES;
}
@end
