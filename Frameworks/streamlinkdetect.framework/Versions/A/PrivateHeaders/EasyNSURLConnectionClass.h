//
//  EasyNSURLConnectionClass.h
//
//  Created by Nanoha Takamachi on 2014/11/25.
//  Copyright (c) 2014年 Atelier Shiori. Licensed under MIT License.
//
//  This class allows easy access to NSURLConnection Functions
//

#import <Foundation/Foundation.h>


@interface EasyNSURLConnection : NSObject{
	/** 
		The user agent of the request. Example: "MAL Updater OS X 2.2.13 (Macintosh; Mac OS X 10.12.3; en_US)"
		@see setUserAgent:
	*/
    NSString * useragent;
	/** 
		The request's headers.
	*/
    NSMutableArray * headers;
	/** 
		The request's Response.
	*/
    __weak NSHTTPURLResponse * response;
	/** 
		The request's response data.
	*/
    NSData * responsedata;
	/** 
		Contains any errors when executing the request.
	*/
    __weak NSError * error;
	/** 
		The URL of the request.
	*/
    NSURL * URL;
	/** 
		States whether or not a request should use cookies or not.
	*/
    BOOL usecookies;
}
/** 
	Initalizes a EasyNSURLConnection instance.
	@return EasyNSURLConnection An instance of EasyNSURLConnection.
*/
-(id)init;
/** 
	Initalizes a EasyNSURLConnection instance with a URL.
	@param address The URL of a request.
	@return EasyNSURLConnection An instance of EasyNSURLConnection.
*/
-(id)initWithURL:(NSURL *)address;
/** 
	Retruns the data from a response as NSData.
	@return NSData The response data.
*/
-(NSData *)getResponseData;
/** 
	Retruns the data from a response as a string.
	@return NSString The response data.
*/
-(NSString *)getResponseDataString;
/** 
	Convenience method to return a JSON response data as an NSArray or NSDictionary.
	@return id The pharsed response data.
*/
-(id)getResponseDataJsonParsed;
/** 
	Returns the status code of a request.
	@return int The status code of a request.
*/
-(long)getStatusCode;
/** 
	Returns the error of an executed request.
	@return NSError The error of the executed request.
*/
-(NSError *)getError;
/** 
	Allows you to add a HTTP header to a request.
	@param object The value of the header.
	@param key The name of the header.
*/
-(void)addHeader:(id)object
         forKey:(NSString *)key;
/** 
	Allows you to specify a custom User Agent
	@param string The user agent.
*/
-(void)setUserAgent:(NSString *)string;
/** 
	Allows you to specify whether or not you should use existing cookies
	@param choice Determines if a request should use cookies or not.
*/
-(void)setUseCookies:(BOOL)choice;
/** 
	Sets a URL
	@param address Specifies a URL for the request.
*/
-(void)setURL:(NSURL *)address;
/** 
	Starts a GET synchronous request.
*/
-(void)startRequest;

@end
