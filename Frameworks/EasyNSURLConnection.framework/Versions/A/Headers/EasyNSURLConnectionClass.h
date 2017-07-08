//
//  EasyNSURLConnectionClass.h
//
//  Created by Nanoha Takamachi on 2014/11/25.
//  Copyright (c) 2014年 Atelier Shiori. Licensed under MIT License.
//
//  This class allows easy access to NSURLConnection Functions
//

#import <Foundation/Foundation.h>
/** 
	This defines the body types of a JSON request.
*/
typedef enum JsonType{
	/** 
		This option will set the body type of a JSON request to "application/json".
		@return 0
	*/
    EasyNSURLConnectionJsonType = 0,
	/** 
		This option will set the body type of a JSON request to "application/vnd.api+json". Some web APIs might require the use of this.
		@return 1
	*/
    EasyNSURLConnectionvndapiJsonType = 1
} EasyNSURLConnectionJsonTypes;

/** 
This constant is used to set the request method to POST 
	@return "POST"
*/
extern NSString * const EasyNSURLPostMethod;
/** 
This constant is used to set the request method to PUT 
	@return "PUT"
*/
extern NSString * const EasyNSURLPutMethod;
/** 
This constant is used to set the request method to PATCH 
	@return "PATCH"
*/
extern NSString * const EasyNSURLPatchMethod;
/** 
This constant is used to set the request method to DELETE 
	@return "DELETE"
*/
extern NSString * const EasyNSURLDeleteMethod;

@interface EasyNSURLConnection : NSObject
/**
 The user agent of the request. Example: "MAL Updater OS X 2.2.13 (Macintosh; Mac OS X 10.12.3; en_US)"
 @see setUserAgent:
	*/
@property (strong) NSString * useragent;
/**
 The post method of a request. (e.g. POST)
	*/
@property (strong) NSString * postmethod;
/**
 The request's headers.
	*/
@property (strong) NSDictionary * headers;
/**
 The request's form data.
	*/
@property (strong) NSMutableArray * formdata;
/**
 The request's Response.
	*/
@property (weak) NSHTTPURLResponse * response;
/**
 The request's response data.
	*/
@property (strong) NSData * responsedata;
/**
 Contains any errors when executing the request.
	*/
@property (weak) NSError * error;
/**
 The URL of the request.
	*/
@property (strong)NSURL * URL;
/**
 States whether or not a request should use cookies or not.
	*/
@property BOOL usecookies;
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
	Allows you to add a parameter containing data.
	@param object The value of the parameter.
	@param key The name of the parameter.
*/
-(void)addFormData:(id)object
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
	Allows you to set the post method (e.g. POST, PUT, PATCH, DELETE). This is not required for GET requests.
	@param method The method of the request.
*/
-(void)setPostMethod:(NSString *)method;
/** 
	Starts a GET synchronous request.
*/
-(void)startRequest;
/** 
	Starts a Form synchronous request. If aa post method is not specified, it will default to POST.
*/
-(void)startFormRequest;
/** 
	Starts a JSON synchronous request with any JSON input. If aa post method is not specified, it will default to POST.
	@param body The JSON data in string format.
	@param bodytype The body type of the JSON data in the body. See JsonType Enums to see aviliable options.
*/
-(void)startJSONRequest:(NSString *)body type:(int)bodytype;
/** 
	Starts a JSON synchronous request with any JSON input. If aa post method is not specified, it will default to POST.
	@param bodytype The body type of the JSON data in the body. See JsonType Enums to see aviliable options.
*/
-(void)startJSONFormRequest:(int)bodytype;
@end
