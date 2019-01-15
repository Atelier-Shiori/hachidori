//
//  Hachidori+MultiScrobble.m
//  Hachidori
//
//  Created by 香風智乃 on 1/14/19.
//

#import "Hachidori+MultiScrobble.h"
#import "Hachidori+Update.h"
#import <AFNetworking/AFNetworking.h>
#import "ScoreConversion.h"

@implementation Hachidori (MultiScrobble)
- (void)multiscrobbleWithType:(MultiScrobbleType)scrobbletype withTitleID:(NSString *)titleid {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults boolForKey:@"multiscrobbleenabled"]) {
        NSDictionary *mapping = [self lookupmappings:titleid];
        switch (scrobbletype) {
            case scrobble:
            case correction:
                [self performMultiScrobbleScrobbleWithMapping:mapping withScrobbleType:scrobbletype];
                break;
            case entryupdate:
                [self performMultiScrobbleEntryUpdateWithMapping:mapping];
                break;
            default:
                break;
        }
    }
}

- (void)performMultiScrobbleScrobbleWithMapping:(NSDictionary *)mapping withScrobbleType:(MultiScrobbleType)type {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (type == correction && self.correcting && ![defaults boolForKey:@"multiscrobblescorrectionsenabled"]) {
        return;
    }
    else if (type == scrobble && !self.correcting && ![defaults boolForKey:@"multiscrobblescrobblesenabled"]) {
        return;
    }
    // Perform MultiScrobble Scrobble
    if ([defaults boolForKey:@"multiscrobblekitsuenabled"] && [Hachidori currentService] != 0) {
        if ([self getFirstAccount:0]) {
            if (mapping[@"kitsu_id"] != [NSNull null] && ((NSNumber *)mapping[@"kitsu_id"]).intValue > 0) {
                int status = [self performupdate:((NSNumber *)mapping[@"kitsu_id"]).stringValue withService:0];
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
    else if ([defaults boolForKey:@"multiscrobbleanilistenabled"] && [Hachidori currentService] != 1) {
        if ([self getFirstAccount:1]) {
            if (mapping[@"anilist_id"] != [NSNull null] && ((NSNumber *)mapping[@"anilist_id"]).intValue > 0) {
                int status = [self performupdate:((NSNumber *)mapping[@"anilist_id"]).stringValue withService:0];
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

- (void)performMultiScrobbleEntryUpdateWithMapping:(NSDictionary *)mapping  {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults boolForKey:@"multiscrobbleentryupdatesenabled"]) {
        // Perform entry update
        if ([defaults boolForKey:@"multiscrobblekitsuenabled"] && [Hachidori currentService] != 0) {
            if ([self getFirstAccount:0]) {
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
            if ([self getFirstAccount:1]) {
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
                     

@end
