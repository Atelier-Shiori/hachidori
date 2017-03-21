//
//  StreamInfoRetrieval.h
//  streamlinkdetect
//
//  Created by 天々座理世 on 2017/03/21.
//  Copyright © 2017年 Atelier Shiori. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StreamInfoRetrieval : NSObject
+(NSDictionary *)retrieveStreamInfo:(NSString*) URL;
+(NSString *)getPageTitle:(NSString *)dom;
@end
