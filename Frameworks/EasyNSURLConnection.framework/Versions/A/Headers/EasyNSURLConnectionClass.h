//
//  EasyNSURLConnection.h
//  MAL Updater OS X
//
//  Created by Nanoha Takamachi on 2014/11/25.
//  Copyright (c) 2014年 Atelier Shiori.
//
//  This class allows easy access to NSURLConnection Functions
//

#import <Foundation/Foundation.h>

@interface EasyNSURLConnection : NSObject{
    NSString * useragent;
    NSString * postmethod;
    NSMutableArray * headers;
    NSMutableArray * formdata;
   __weak NSHTTPURLResponse * response;
    NSData * responsedata;
    __weak NSError * error;
    NSURL * URL;
    BOOL usecookies;
}
@property(weak) NSURLResponse * response;
@property(weak) NSError * error;
-(id)init;
-(id)initWithURL:(NSURL *)address;
-(NSData *)getResponseData;
-(NSString *)getResponseDataString;
-(long)getStatusCode;
-(NSError *)getError;
-(void)addHeader:(id)object
         forKey:(NSString *)key;
-(void)addFormData:(id)object
           forKey:(NSString *)key;
-(void)setUserAgent:(NSString *)string;
-(void)setUseCookies:(BOOL)choice;
-(void)setURL:(NSURL *)address;
-(void)setPostMethod:(NSString *)method;
-(void)startRequest;
-(void)startFormRequest;
-(void)startJSONRequest:(NSString *)body;
-(void)startJSONFormRequest;
@end
