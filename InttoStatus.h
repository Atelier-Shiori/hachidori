//
//  InttoStatus.h
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/01/10.
//  Copyright 2009-2017 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Foundation/Foundation.h>

@interface InttoStatus : NSValueTransformer
+ (Class)transformedValueClass;
-(id)transformedValue:(id)value;
@end
