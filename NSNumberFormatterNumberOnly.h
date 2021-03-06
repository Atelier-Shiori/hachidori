//
//  NSNumberFormatterNumberOnly.h
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/03/05.
//  Copyright © 2017 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import <Foundation/Foundation.h>

@interface NSNumberFormatterNumberOnly : NSNumberFormatter
- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **) error ;
@end
