//
//  Hachidori+AnimeRelations.m
//  Hachidori
//
//  Created by 天々座理世 on 2018/05/23.
//

#import "Hachidori+AnimeRelations.h"
#import "AnimeRelations.h"

@implementation Hachidori (AnimeRelations)
- (int)checkAnimeRelations:(int)titleid {
    int currentservice = (int)[Hachidori currentService];
    NSArray *relations = [AnimeRelations retrieveRelationsEntriesForTitleID:titleid withService:currentservice];
    for (NSManagedObject *relation in relations) {
        @autoreleasepool {
            NSNumber *sourcefromepisode = [relation valueForKey:@"source_ep_from"];
            NSNumber *sourcetoepisode = [relation valueForKey:@"source_ep_to"];
            NSNumber *targetfromepisode = [relation valueForKey:@"target_ep_from"];
            NSNumber *targettoepisode = [relation valueForKey:@"target_ep_to"];
            NSNumber *iszeroepisode = [relation valueForKey:@"is_zeroepisode"];
            NSNumber *targetid;
            switch (currentservice) {
                case 0:
                    targetid = [relation valueForKey:@"target_kitsuid"];
                    break;
                case 1:
                    targetid = [relation valueForKey:@"target_anilistid"];
                    break;
                case 2:
                    targetid = [relation valueForKey:@"target_malid"];
                    break;
                default:
                    break;
            }
                    
            if (self.detectedscrobble.DetectedEpisode.intValue < sourcefromepisode.intValue && self.detectedscrobble.DetectedEpisode.intValue > sourcetoepisode.intValue) {
                continue;
            }
            int tmpep = self.detectedscrobble.DetectedEpisode.intValue - (sourcefromepisode.intValue-1);
            if (tmpep > 0 && tmpep <= targettoepisode.intValue) {
                self.detectedscrobble.DetectedEpisode = @(tmpep).stringValue;
                return targetid.intValue;
            }
            else if (self.detectedscrobble.DetectedTitleisEpisodeZero && iszeroepisode.boolValue) {
                self.detectedscrobble.DetectedEpisode = targetfromepisode.stringValue;
                return targetid.intValue;
            }
            else if (self.detectedscrobble.DetectedTitleisMovie && targetfromepisode.intValue == targettoepisode.intValue) {
                self.detectedscrobble.DetectedEpisode = targetfromepisode.stringValue;
                return targetid.intValue;
            }
        }
    }
    return -1;
}

- (bool)checkAnimeRelationsForExisting:(int)titleid {
    int currentservice = (int)[Hachidori currentService];
    NSArray *relations = [AnimeRelations retrieveTargetRelationsEntriesForTitleID:titleid withService:currentservice];
    for (NSManagedObject *relation in relations) {
        @autoreleasepool {
            NSNumber *sourcefromepisode = [relation valueForKey:@"source_ep_from"];
            NSNumber *sourcetoepisode = [relation valueForKey:@"source_ep_to"];
            NSNumber *targetfromepisode = [relation valueForKey:@"target_ep_from"];
            NSNumber *targettoepisode = [relation valueForKey:@"target_ep_to"];
            NSNumber *iszeroepisode = [relation valueForKey:@"is_zeroepisode"];
            NSNumber *targetid;
            switch (currentservice) {
                case 0:
                    targetid = [relation valueForKey:@"target_kitsuid"];
                    break;
                case 1:
                    targetid = [relation valueForKey:@"target_anilistid"];
                    break;
                case 2:
                    targetid = [relation valueForKey:@"target_malid"];
                    break;
                default:
                    break;
            }
                    
            if (self.detectedscrobble.DetectedEpisode.intValue < sourcefromepisode.intValue && self.detectedscrobble.DetectedEpisode.intValue > sourcetoepisode.intValue) {
                continue;
            }
            int tmpep = self.detectedscrobble.DetectedEpisode.intValue - (sourcefromepisode.intValue-1);
            if (tmpep > 0 && tmpep <= targettoepisode.intValue) {
                self.detectedscrobble.DetectedEpisode = @(tmpep).stringValue;
                return YES;
            }
            else if (self.detectedscrobble.DetectedTitleisEpisodeZero && iszeroepisode.boolValue) {
                self.detectedscrobble.DetectedEpisode = targetfromepisode.stringValue;
                return YES;
            }
            else if (self.detectedscrobble.DetectedTitleisMovie && targetfromepisode.intValue == targettoepisode.intValue) {
                self.detectedscrobble.DetectedEpisode = targetfromepisode.stringValue;
                return YES;
            }
        }
    }
    return NO;
}
@end
