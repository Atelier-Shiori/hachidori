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
    int currentservice = (int)self.currentService;
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
                default:
                    break;
            }
                    
            if (self.DetectedEpisode.intValue < sourcefromepisode.intValue && self.DetectedEpisode.intValue > sourcetoepisode.intValue) {
                continue;
            }
            int tmpep = self.DetectedEpisode.intValue - (sourcefromepisode.intValue-1);
            if (tmpep > 0 && tmpep <= targettoepisode.intValue) {
                self.DetectedEpisode = @(tmpep).stringValue;
                return targetid.intValue;
            }
            else if (self.DetectedTitleisEpisodeZero && iszeroepisode.boolValue) {
                self.DetectedEpisode = targetfromepisode.stringValue;
                return targetid.intValue;
            }
            else if (self.DetectedTitleisMovie && targetfromepisode.intValue == targettoepisode.intValue) {
                self.DetectedEpisode = targetfromepisode.stringValue;
                return targetid.intValue;
            }
        }
    }
    return -1;
}
@end
