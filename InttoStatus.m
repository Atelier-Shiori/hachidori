//
//  InttoStatus.m
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/01/10.
//  Copyright 2009-2017 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "InttoStatus.h"

@implementation InttoStatus
+ (Class)transformedValueClass
{
    return [NSString class];
}

-(id)transformedValue:(id)value{
    if (!value) return nil;
    
    if ([value respondsToSelector:@selector(integerValue)]) {
        int status = [value intValue];
        switch (status) {
            case 23:
                return @"Queued";
            case 2:
                return @"Update Not Needed";
            case 3:
                return @"Awaiting Confirmation";
            case 21:
            case 22:
                return @"Successful";
            case 51:
            case 52:
            case 53:
            case 54:
                return @"Unsuccessful";
        }
    }
    return nil;
}
@end
