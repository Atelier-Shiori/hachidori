//
//  AniListScoreConvert.h
//  Shukofukurou
//
//  Created by 小鳥遊六花 on 4/5/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AniListScoreConvert : NSObject
+ (NSString *)convertAniListScoreToActualScore: (int)score withScoreType:(int)scoretype;
+ (int)convertScoretoScoreRaw:(double)score withScoreType:(int)scoretype;
+ (NSNumber *)convertScoreToRawActualScore:(int)score withScoreType:(int)scoretype;
@end
