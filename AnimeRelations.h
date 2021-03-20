//
//  AnimeRelations.h
//  MAL Updater OS X
//
//  Created by 小鳥遊六花 on 5/7/18.
//

#import <AppKit/AppKit.h>

@interface AnimeRelations : NSObject
+ (void)updateRelations;
+ (NSArray *)retrieveRelationsEntriesForTitleID:(int)titleid withService:(int)service;
+ (NSArray *)retrieveTargetRelationsEntriesForTitleID:(int)titleid withService:(int)servic;
+ (void)clearAnimeRelations;
@end
