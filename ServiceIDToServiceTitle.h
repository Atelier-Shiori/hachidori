//
//  ServiceIDToServiceTitle.h
//  Hachidori
//
//  Created by 天々座理世 on 2018/07/22.
//

#import <Foundation/Foundation.h>

@interface ServiceIDToServiceTitle : NSValueTransformer
+ (Class)transformedValueClass;
- (id)transformedValue:(id)value;
@end
