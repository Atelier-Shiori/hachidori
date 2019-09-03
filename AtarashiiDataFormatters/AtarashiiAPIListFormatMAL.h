//
//  AtarashiiAPIListFormatMAL.h
//  Hakuchou
//
//  Created by 香風智乃 on 8/23/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AtarashiiAPIListFormatMAL : NSObject
+ (NSDictionary *)MALtoAtarashiiAnimeEntry:(id)data;
+ (NSDictionary *)MALAnimeInfotoAtarashii:(NSDictionary *)data;
+ (NSArray *)MALAnimeSearchtoAtarashii:(NSDictionary *)data;
@end

NS_ASSUME_NONNULL_END
