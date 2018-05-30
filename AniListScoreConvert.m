//
//  AniListScoreConvert.m
//  Shukofukurou
//
//  Created by 小鳥遊六花 on 4/5/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AniListScoreConvert.h"
#import "Hachidori.h"

@implementation AniListScoreConvert
+ (NSNumber *)convertAniListScoreToActualScore: (int)score withScoreType:(int)scoretype {
    return [self convertScoreToRawActualScore:score withScoreType:scoretype];
    
}
+ (NSNumber *)convertScoreToRawActualScore:(int)score withScoreType:(int)scoretype {
    switch (scoretype) {
        case ratingPoint100: {
            return @(score);
        }
        case ratingPoint10Decimal: {
            return @((double)score/10);
        }
        case ratingPoint10: {
            long rounded = roundl((double)score/10);
            return @(rounded);
        }
        case ratingPoint5: {
            long rounded = roundl((double)score/10);
            rounded = roundl((double)rounded/2);
            return @(rounded);
        }
        case ratingPoint3: {
            int finalscore = 0;
            if (score > 0 && score <= 33) {
                finalscore = 1;
            }
            else if (score > 33 && score <=67) {
                finalscore = 2;
            }
            else if (score > 67 && score <= 100) {
                finalscore = 3;
            }
            return @(finalscore);
        }
        default: {
            return @(score);
        }
    }
}
+ (int)convertScoretoScoreRaw:(double)score withScoreType:(int)scoretype {
    switch (scoretype) {
        case ratingPoint100: {
            return (int)score;
        }
        case ratingPoint10Decimal:
        case ratingPoint10: {
            return (int)score*10;
        }
        case ratingPoint5: {
            return (int)(score*2)*10;
        }
        case ratingPoint3: {
            switch ((int)score) {
                case 0:
                    return 0;
                case 1:
                    return 30;
                case 2:
                    return 60;
                case 3:
                    return 100;
                default:
                    break;
            }
        }
        default: {
            return (int)score;
        }
    }

}



@end
