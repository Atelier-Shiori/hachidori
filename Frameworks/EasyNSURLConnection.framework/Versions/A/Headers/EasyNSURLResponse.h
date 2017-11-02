//
//  EasyNSURLResponse.h
//  EasyNSURLConnection
//
//  Created by 桐間紗路 on 2017/03/03.
//  Copyright © 2017 Atelier Shiori. All rights reserved. Licensed under MIT License.
//

#import <Foundation/Foundation.h>
/**
 This class specifies the response object when a request is done.
 */
@interface EasyNSURLResponse : NSObject
/**
 The request's response data.
 */
@property (nonatomic, copy, getter=getData) NSData * responsedata;
/**
 Contains any errors when executing the request.
 */
@property (nonatomic, copy, getter=getError) NSError * error;
/**
 The request's Response.
 */
@property (nonatomic, copy, getter=getResponse) NSHTTPURLResponse * response;
/**
 Initalizes aa request object. Not to be called by the user.
 */
- (id)initWithData:(NSData *)rdata withResponse:(NSHTTPURLResponse *)rresponse withError:(NSError*)eerror;
/**
 Retruns the data from a response as a string.
 @return NSString The response data.
 */
- (NSString *)getResponseDataString;
/**
 Convenience method to return a JSON response data as an NSArray or NSDictionary.
 @return id The pharsed response data.
 */
- (id)getResponseDataJsonParsed;
/**
 Returns the status code of a request.
 @return int The status code of a request.
 */
- (long)getStatusCode;
@end
