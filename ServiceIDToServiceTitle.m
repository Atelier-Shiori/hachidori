//
//  ServiceIDToServiceTitle.m
//  Hachidori
//
//  Created by 天々座理世 on 2018/07/22.
//

#import "ServiceIDToServiceTitle.h"

@implementation ServiceIDToServiceTitle
+ (Class)transformedValueClass
{
    return [NSString class];
}

- (id)transformedValue:(id)value{
    if (!value) return nil;
    
    if ([value respondsToSelector:@selector(integerValue)]) {
        int service = [value intValue];
        switch (service) {
            case 0:
                return @"Kitsu";
            case 1:
                return @"AniList";
            case 2:
                return @"MyAnimeList";
            default:
                break;
        }
        return @"";
    }
    return nil;
}
@end
