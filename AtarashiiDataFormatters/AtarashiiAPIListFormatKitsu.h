//
//  AtarashiiAPIListFormatKitsu.h
//  Shukofukurou
//
//  Created by 桐間紗路 on 2017/12/18.
//  Copyright © 2017年 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AtarashiiAPIListFormatKitsu: NSObject
+ (NSDictionary *)KitsuAnimeListEntrytoAtarashii:(id)data;
+ (NSDictionary *)KitsuAnimeInfotoAtarashii:(NSDictionary *)data;
+ (NSArray *)KitsuAnimeSearchtoAtarashii:(NSDictionary *)data;
@end
