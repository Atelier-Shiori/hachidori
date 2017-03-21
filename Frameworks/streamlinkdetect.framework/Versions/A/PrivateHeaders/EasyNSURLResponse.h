//
//  EasyNSURLResponse.h
//  EasyNSURLConnection
//
//  Created by 桐間紗路 on 2017/03/03.
//  Copyright © 2017 Atelier Shiori. All rights reserved. Licensed under MIT License.
//

#import <Foundation/Foundation.h>

@interface EasyNSURLResponse : NSObject
@property (nonatomic, copy, getter=getData) NSData * responsedata;
@property (nonatomic, copy, getter=getError) NSError * error;
@property (nonatomic, copy, getter=getResponse) NSHTTPURLResponse * response;
-(id)initWithData:(NSData *)rdata withResponse:(NSHTTPURLResponse *)rresponse withError:(NSError*)eerror;
@end
