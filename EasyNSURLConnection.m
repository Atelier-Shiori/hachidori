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
    if (formdata == nil) {
        //Initalize Header Data Array
        headers = [[NSMutableArray alloc] init];
    }
    [headers addObject:[NSDictionary dictionaryWithObjectsAndKeys:object,key, nil]];
}
-(void)addFormData:(id)object
           forKey:(NSString *)key{
    if (formdata == nil) {
        //Initalize Form Data Array
        formdata = [[NSMutableArray alloc] init];
    }
    [formdata addObject:[NSDictionary dictionaryWithObjectsAndKeys:object,key, nil]];
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
    // Set Other headers, if any
    if (headers != nil) {
        for (NSDictionary *d in headers ) {
            //Set any headers
            [request setValue:[[d allValues] objectAtIndex:0]forHTTPHeaderField:[[d allKeys] objectAtIndex:0]];
        }
    }
    NSError * rerror = nil;
    responsedata = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&rresponse
                                                     error:&rerror];
    error = rerror;
    response = rresponse;
    
}
-(void)startFormRequest{
    // Send a synchronous request
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:URL];
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
    //Set Post Data
    [request setHTTPBody:[self encodeArraywithDictionaries:formdata]];
    // Set Other headers, if any
    if (headers != nil) {
        for (NSDictionary *d in headers ) {
            //Set any headers
            [request setValue:[[d allValues] objectAtIndex:0]forHTTPHeaderField:[[d allKeys] objectAtIndex:0]];
        }
    }
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
@end
