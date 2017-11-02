//
//  EasyNSURLConnectionClass.h
//
//  Created by Nanoha Takamachi on 2014/11/25.
//  Copyright (c) 2014年 Atelier Shiori. Licensed under MIT License.
//
//  This class allows easy creation of synchronous and asynchronous request using NSURLSession
//

#import <Foundation/Foundation.h>
/**
     This class allows easy creation of synchronous and asynchronous request using NSURLSession
 */
@class EasyNSURLResponse;
/** 
	This defines the body types of a JSON request.
*/
typedef enum JsonType{
	/** 
		This option will set the body type of a JSON request to "application/json".
	*/
    EasyNSURLConnectionJsonType = 0,
	/** 
		This option will set the body type of a JSON request to "application/vnd.api+json". Some web APIs might require this.
	*/
    EasyNSURLConnectionvndapiJsonType = 1
} EasyNSURLConnectionJsonTypes;

/** 
This constant is used to set the request method to POST
*/
extern NSString * const EasyNSURLPostMethod;
/**
 This constant is used to set the request method to HEAD
 */
extern NSString * const EasyNSURLHeadMethod;
/** 
This constant is used to set the request method to PUT
*/
extern NSString * const EasyNSURLPutMethod;
/** 
This constant is used to set the request method to PATCH
*/
extern NSString * const EasyNSURLPatchMethod;
/** 
This constant is used to set the request method to DELETE
*/
extern NSString * const EasyNSURLDeleteMethod;

@interface EasyNSURLConnection : NSObject
/**
    The user agent of the request. Example: "MAL Updater OS X 2.2.13 (Macintosh; Mac OS X 10.12.3; en_US)"
    @see setUserAgent:
*/
@property (strong, setter=setUserAgent:) NSString *useragent;
/**
    The post method of a request. (e.g. POST)
*/
@property (strong, setter=setPostMethod:) NSString *postmethod;
/**
    The request's headers.
*/
@property (strong) NSMutableDictionary *headers;
/**
    The request's form data.
*/
@property (strong, setter=setFormData:) NSMutableDictionary *formdata;
/**
     The request's response
 */
@property (strong, getter=getResponse) EasyNSURLResponse *response;
/**
    Contains any errors when executing the request.
*/
@property (weak, getter=getError) NSError *error;
/**
    The URL of the request.
*/
@property (strong, setter=setURL:, getter=getURL) NSURL *URL;
/**
    States whether or not a request should use cookies or not.
*/
@property (setter=setUseCookies:) BOOL usecookies;
/**
 This property will make EasyURLConnection to send JSON data opposed to URL Encoded
 */
@property (setter=setuseJSON:) bool usejson;
/**
 This property sets the JSON type if usejson propertty is true or YES
 */
@property (setter=setJSONType:) int jsontype;
/**
 */
@property (setter=setJSONBody:) NSString *jsonbody;
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
	Allows you to add a HTTP header to a request.
	@param object The value of the header.
	@param key The name of the header.
*/
-(void)addHeader:(id)object
         forKey:(NSString *)key;
/** 
	Allows you to add a parameter containing data.
	@param object The value of the parameter.
	@param key The name of the parameter.
*/
-(void)addFormData:(id)object
           forKey:(NSString *)key;
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
/**
     Performs a asynchronous GET request.
     @param url A url of a request.
     @param headers The headers to add to a request.
     @param completion A block object that is executed when a request is successful. Block have an EasyNSURLResponse object as arguments and no return values.
     @param error A block object that is executed when a request fails. Block have an NSError and integer containing the HTTP status code and no return values;
 */
- (void)GET:(NSString *)url headers:(NSDictionary *)headers completion:(void (^)(EasyNSURLResponse *response))completion error:(void (^)(NSError *error, int statuscode))error;
/**
     Performs a asynchronous HEAD request.
     @param url A url of a request.
     @param param Contains parameters/form data of a request;
     @param headers The headers to add to a request.
     @param completion A block object that is executed when a request is successful. Block have an EasyNSURLResponse object as arguments and no return values.
     @param error A block object that is executed when a request fails. Block have an NSError and integer containing the HTTP status code and no return values;
 */
- (void)HEAD:(NSString *)url parameters:(NSDictionary *)param headers:(NSDictionary *)headers completion:(void (^)(EasyNSURLResponse *response))completion error:(void (^)(NSError *error, int statuscode))error;
/**
     Performs a asynchronous PATCH request.
     @param url A url of a request.
     @param param Contains parameters/form data of a request;
     @param headers The headers to add to a request.
     @param completion A block object that is executed when a request is successful. Block have an EasyNSURLResponse object as arguments and no return values.
     @param error A block object that is executed when a request fails. Block have an NSError and integer containing the HTTP status code and no return values;
 */
- (void)PATCH:(NSString *)url parameters:(NSDictionary *)param headers:(NSDictionary *)headers completion:(void (^)(EasyNSURLResponse *response))completion error:(void (^)(NSError *error, int statuscode))error;
/**
 Performs a asynchronous POST request.
 @param url A url of a request.
 @param param Contains parameters/form data of a request;
 @param headers The headers to add to a request.
 @param completion A block object that is executed when a request is successful. Block have an EasyNSURLResponse object as arguments and no return values.
 @param error A block object that is executed when a request fails. Block have an NSError and integer containing the HTTP status code and no return values;
 */
- (void)POST:(NSString *)url parameters:(NSDictionary *)param headers:(NSDictionary *)headers completion:(void (^)(EasyNSURLResponse *response))completion error:(void (^)(NSError *error, int statuscode))error;
/**
 Performs a asynchronous PUT request.
 @param url A url of a request.
 @param param Contains parameters/form data of a request;
 @param headers The headers to add to a request.
 @param completion A block object that is executed when a request is successful. Block have an EasyNSURLResponse object as arguments and no return values.
 @param error A block object that is executed when a request fails. Block have an NSError and integer containing the HTTP status code and no return values;
 */
- (void)PUT:(NSString *)url parameters:(NSDictionary *)param headers:(NSDictionary *)headers completion:(void (^)(EasyNSURLResponse *response))completion error:(void (^)(NSError *error, int statuscode))error;
/**
     Performs a asynchronous DELETE request.
     @param url A url of a request.
     @param param Contains parameters/form data of a request;
     @param headers The headers to add to a request.
     @param completion A block object that is executed when a request is successful. Block have an EasyNSURLResponse object as arguments and no return values.
     @param error A block object that is executed when a request fails. Block have an NSError and integer containing the HTTP status code and no return values;
 */
- (void)DELETE:(NSString *)url parameters:(NSDictionary *)param headers:(NSDictionary *)headers completion:(void (^)(EasyNSURLResponse *response))completion error:(void (^)(NSError *error, int statuscode))error;
@end
