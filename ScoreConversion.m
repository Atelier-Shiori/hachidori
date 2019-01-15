//
//  ScoreConversion.m
//  Hachidori
//
//  Created by 香風智乃 on 1/15/19.
//

#import "ScoreConversion.h"

@implementation ScoreConversion

+ (int)translateadvancedKitsuRatingtoRatingTwenty:(double)score {
    if (score == 1.0) {
        return 2;
    }
    else if (score == 1.5) {
        return 3;
    }
    else if (score == 2.0) {
        return 4;
    }
    else if (score == 2.5) {
        return 5;
    }
    else if (score == 3.0) {
        return 6;
    }
    else if (score == 3.5) {
        return 7;
    }
    else if (score == 4.0) {
        return 8;
    }
    else if (score == 4.5) {
        return 9;
    }
    else if (score == 5.0) {
        return 10;
    }
    else if (score == 5.5) {
        return 11;
    }
    else if (score == 6.0) {
        return 12;
    }
    else if (score == 6.5) {
        return 13;
    }
    else if (score == 7.0) {
        return 14;
    }
    else if (score == 7.5) {
        return 15;
    }
    else if (score == 8.0) {
        return 16;
    }
    else if (score == 8.5) {
        return 17;
    }
    else if (score == 9.0) {
        return 18;
    }
    else if (score == 9.5) {
        return 19;
    }
    else if (score == 10.0) {
        return 20;
    }
    return 0;
}
+ (int)ratingTwentytoAdvancedScore:(int)twentyrating {
    double advrating = 0.0;
    switch (twentyrating) {
        case 2:
            advrating = 1.0;
            break;
        case 3:
            advrating = 1.5;
            break;
        case 4:
            advrating = 2.0;
            break;
        case 5:
            advrating = 2.5;
            break;
        case 6:
            advrating = 3.0;
            break;
        case 7:
            advrating = 3.5;
            break;
        case 8:
            advrating = 4.0;
            break;
        case 9:
            advrating = 4.5;
            break;
        case 10:
            advrating = 5.0;
            break;
        case 11:
            advrating = 5.5;
            break;
        case 12:
            advrating = 6.0;
            break;
        case 13:
            advrating = 6.5;
            break;
        case 14:
            advrating = 7.0;
            break;
        case 15:
            advrating = 7.5;
            break;
        case 16:
            advrating = 8.0;
            break;
        case 17:
            advrating = 8.5;
            break;
        case 18:
            advrating = 9.0;
            break;
        case 19:
            advrating = 9.5;
            break;
        case 20:
            advrating = 10.0;
            break;
        default:
            break;
    }
    return (int)advrating*10;
}
@end
