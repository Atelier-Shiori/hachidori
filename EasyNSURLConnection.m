//
//  EasyNSURLConnection.m
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/11/25.
//  Copyright (c) 2014年 Atelier Shiori.
//
//  This class allows easy access to NSURLConnection Functions
//

#import "EasyNSURLConnection.h"

@implementation EasyNSURLConnection
@synthesize error;
@synthesize response;

#pragma constructors
-(id)init{
    // Set Default User Agent
    useragent =[NSString stringWithFormat:@"%@ %@ (Macintosh; Mac OS X %@; %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"],[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"], [[NSLocale currentLocale] localeIdentifier]];
    return [super init];
}
-(id)initWithURL:(NSURL *)address{
    URL = address;
    return [self init];
}
#pragma getters
-(NSData *)getResponseData{
    return responsedata;
}
-(NSString *)getResponseDataString{
    NSString * datastring = [[NSString alloc] initWithData:responsedata encoding:NSUTF8StringEncoding];
    return datastring;
}
-(long)getStatusCode{
    return response.statusCode;
}
-(NSError *)getError{
    return error;
}
#pragma mutators
-(void)addHeader:(id)object
         forKey:(NSString *)key{
    NSLock * lock = [NSLock new]; // NSMutableArray is not Thread Safe, lock before performing operation
    [lock lock];
    if (formdata == nil) {
        //Initalize Header Data Array
        headers = [[NSMutableArray alloc] init];
    }
    [headers addObject:[NSDictionary dictionaryWithObjectsAndKeys:object,key, nil]];
    [lock unlock]; //Finished operation, unlock
}
-(void)addFormData:(id)object
           forKey:(NSString *)key{
    NSLock * lock = [NSLock new]; // NSMutableArray is not Thread Safe, lock before performing operation
    [lock lock];
    if (formdata == nil) {
        //Initalize Form Data Array
        formdata = [[NSMutableArray alloc] init];
    }
    [formdata addObject:[NSDictionary dictionaryWithObjectsAndKeys:object,key, nil]];
    [lock unlock]; //Finished operation, unlock
}
-(void)setUserAgent:(NSString *)string{
    useragent = [NSString stringWithFormat:@"%@",string];
}
-(void)setUseCookies:(BOOL)choice{
    usecookies = choice;
}
-(void)setURL:(NSURL *)address{
    URL = address;
}
-(void)setPostMethod:(NSString *)method{
    postmethod = method;
}
#pragma request functions
-(void)startRequest{
    // Send a synchronous request
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:URL];
    NSHTTPURLResponse * rresponse = nil;
    // Do not use Cookies
    [request setHTTPShouldHandleCookies:usecookies];
    // Set Timeout
    [request setTimeoutInterval:15];
    // Set User Agent
    [request setValue:useragent forHTTPHeaderField:@"User-Agent"];
    NSLock * lock = [NSLock new]; // NSMutableArray is not Thread Safe, lock before performing operation
    [lock lock];
    // Set Other headers, if any
    if (headers != nil) {
        for (NSDictionary *d in headers ) {
            //Set any headers
            [request setValue:[[d allValues] objectAtIndex:0]forHTTPHeaderField:[[d allKeys] objectAtIndex:0]];
        }
    }
    [lock unlock];
    NSError * rerror = nil;
    responsedata = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&rresponse
                                                     error:&rerror];
    error = rerror;
    response = rresponse;
    
}
-(void)startoAuthRequest{
    // Send a synchronous request
    NXOAuth2Request *sRequest = [[NXOAuth2Request alloc] initWithResource:URL
                                                                   method:@"GET"
                                                               parameters:nil];
    [sRequest setAccount:[self getFirstAccount]];
    NSMutableURLRequest * request = (NSMutableURLRequest *)[sRequest signedURLRequest];
    NSHTTPURLResponse * rresponse = nil;
    // Do not use Cookies
    [request setHTTPShouldHandleCookies:usecookies];
    // Set Timeout
    [request setTimeoutInterval:15];
    // Set User Agent
    [request setValue:useragent forHTTPHeaderField:@"User-Agent"];
    NSLock * lock = [NSLock new]; // NSMutableArray is not Thread Safe, lock before performing operation
    [lock lock];
    // Set Other headers, if any
    if (headers != nil) {
        for (NSDictionary *d in headers ) {
            //Set any headers
            [request setValue:[[d allValues] objectAtIndex:0]forHTTPHeaderField:[[d allKeys] objectAtIndex:0]];
        }
    }
    [lock unlock];
    NSError * rerror = nil;
    responsedata = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&rresponse
                                                     error:&rerror];
    error = rerror;
    response = rresponse;
    
}
-(void)startFormRequest{
    // Send a synchronous request
    NXOAuth2Request *sRequest = [[NXOAuth2Request alloc] initWithResource:URL
                                                                   method:@"POST"
                                                               parameters:nil];
    [sRequest setAccount:[self getFirstAccount]];
    NSMutableURLRequest * request = (NSMutableURLRequest *)[sRequest signedURLRequest];
    NSHTTPURLResponse * rresponse = nil;
    // Set Method
    if (postmethod.length != 0) {
        [request setHTTPMethod:postmethod];
    }
    else
        [request setHTTPMethod:@"POST"];
    // Set content type to form data
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    // Do not use Cookies
    [request setHTTPShouldHandleCookies:usecookies];
    // Set User Agent
    [request setValue:useragent forHTTPHeaderField:@"User-Agent"];
    // Set Timeout
    [request setTimeoutInterval:15];
    NSLock * lock = [NSLock new]; // NSMutableArray is not Thread Safe, lock before performing operation
    [lock lock];
    //Set Post Data
    [request setHTTPBody:[self encodeArraywithDictionaries:formdata]];
    // Set Other headers, if any
    if (headers != nil) {
        for (NSDictionary *d in headers ) {
            //Set any headers
            [request setValue:[[d allValues] objectAtIndex:0]forHTTPHeaderField:[[d allKeys] objectAtIndex:0]];
        }
    }
    [lock unlock];
    NSError * rerror;
    responsedata = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&rresponse
                                                     error:&rerror];
    error = rerror;
    response = rresponse;
}
-(void)startJSONFormRequest{
    // Send a synchronous request
    NXOAuth2Request *sRequest = [[NXOAuth2Request alloc] initWithResource:URL
                                                                   method:@"POST"
                                                               parameters:nil];
    [sRequest setAccount:[self getFirstAccount]];
    NSMutableURLRequest * request = (NSMutableURLRequest *)[sRequest signedURLRequest];
    NSHTTPURLResponse * rresponse = nil;
    // Set Method
    if (postmethod.length != 0) {
        [request setHTTPMethod:postmethod];
    }
    else
        [request setHTTPMethod:@"POST"];
    // Set content type to form data
    [request setValue:@"application/vnd.api+json" forHTTPHeaderField:@"Content-Type"];
    // Do not use Cookies
    [request setHTTPShouldHandleCookies:usecookies];
    // Set User Agent
    [request setValue:useragent forHTTPHeaderField:@"User-Agent"];
    // Set Timeout
    [request setTimeoutInterval:5];
    NSLock * lock = [NSLock new]; // NSMutableArray is not Thread Safe, lock before performing operation
    [lock lock];
    //Set Post Data
    NSError *jerror;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self arraytodictionary:formdata] options:0 error:&jerror];
    if (!jsonData) {}
    else{
        NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
        [request setHTTPBody:[JSONString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    // Set Other headers, if any
    if (headers != nil) {
        for (NSDictionary *d in headers ) {
            //Set any headers
            [request setValue:[[d allValues] objectAtIndex:0]forHTTPHeaderField:[[d allKeys] objectAtIndex:0]];
        }
    }
    [lock unlock];
    NSError * rerror;
    responsedata = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&rresponse
                                                     error:&rerror];
    error = rerror;
    response = rresponse;
}
-(void)startJSONRequest:(NSString *)body{
    // Send a synchronous request
    NXOAuth2Request *sRequest = [[NXOAuth2Request alloc] initWithResource:URL
                                                                   method:@"POST"
                                                               parameters:nil];
    [sRequest setAccount:[self getFirstAccount]];
    NSMutableURLRequest * request = (NSMutableURLRequest *)[sRequest signedURLRequest];
    NSHTTPURLResponse * rresponse = nil;
    // Set Method
    if (postmethod.length != 0) {
        [request setHTTPMethod:postmethod];
    }
    else
        [request setHTTPMethod:@"POST"];
    // Set content type to form data
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    // Do not use Cookies
    [request setHTTPShouldHandleCookies:usecookies];
    // Set User Agent
    [request setValue:useragent forHTTPHeaderField:@"User-Agent"];
    // Set Timeout
    [request setTimeoutInterval:5];
    NSLock * lock = [NSLock new]; // NSMutableArray is not Thread Safe, lock before performing operation
    [lock lock];
    //Set Post Data
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    // Set Other headers, if any
    if (headers != nil) {
        for (NSDictionary *d in headers ) {
            //Set any headers
            [request setValue:[[d allValues] objectAtIndex:0]forHTTPHeaderField:[[d allKeys] objectAtIndex:0]];
        }
    }
    [lock unlock];
    NSError * rerror;
    responsedata = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&rresponse
                                                     error:&rerror];
    error = rerror;
    response = rresponse;
}

#pragma helpers
- (NSData*)encodeArraywithDictionaries:(NSArray*)array {
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    for (NSDictionary * d in array) {
        NSString *encodedValue = [[d objectForKey:[[d allKeys] objectAtIndex:0]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedKey = [[[d allKeys] objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject:part];
    }
    NSString *encodedDictionary = [parts componentsJoinedByString:@"&"];
    return [encodedDictionary dataUsingEncoding:NSUTF8StringEncoding];
}
-(NSDictionary *)arraytodictionary:(NSArray *)array{
    NSMutableDictionary * doutput = [NSMutableDictionary new];
    for (NSDictionary * d in array) {
        NSString * akey = [[d allKeys] objectAtIndex:0];
        NSString *acontent = [d objectForKey:[[d allKeys] objectAtIndex:0]];
        [doutput setObject:acontent forKey:akey];
        }
    return doutput;
}
-(NXOAuth2Account *)getFirstAccount{
    for (NXOAuth2Account *account in [[NXOAuth2AccountStore sharedStore] accounts]) {
        return account;
    };
    return nil;
}
@end
