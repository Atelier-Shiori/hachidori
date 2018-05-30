//
//  AtarashiiAPIListFormatAniList.h
//  Shukofukurou
//
//  Created by 天々座理世 on 2018/03/27.
//  Copyright © 2018年 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AtarashiiAPIListFormatAniList : NSObject
+ (id)AniListtoAtarashiiAnimeSingle:(id)data;
+ (NSDictionary *)AniListAnimeInfotoAtarashii:(NSDictionary *)data;
+ (NSArray *)AniListAnimeSearchtoAtarashii:(NSDictionary *)data;;
@end
