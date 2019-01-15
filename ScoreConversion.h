//
//  ScoreConversion.h
//  Hachidori
//
//  Created by 香風智乃 on 1/15/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScoreConversion : NSObject
+ (int)translateadvancedKitsuRatingtoRatingTwenty:(double)score;
+ (int)ratingTwentytoAdvancedScore:(int)twentyrating;
@end

NS_ASSUME_NONNULL_END
