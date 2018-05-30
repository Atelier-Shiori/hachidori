//
//  TwitterManager.h
//  TwitterManagerTest
//
//  Created by 天々座理世 on 2018/01/23.
//  Copyright © 2018年 Moy IT Solutions. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface TwitterManager : NSObject
- (id)initWithConsumerKey:(NSString *)consumerkey withConsumerSecret:(NSString *)consumersecret;
- (id)initWithConsumerKey:(NSString *)consumerkey withConsumerSecret:(NSString *)consumersecret withUsername:(NSString *)username;
- (id)initWithConsumerKeyUsingFirstAccount:(NSString *)consumerkey withConsumerSecret:(NSString *)consumersecret;
- (bool)accountexists;
- (NSDictionary *)getFirstAccount;
- (NSDictionary *)retrieveToken:(NSString *)username;
- (bool)tokenexists:(NSString *)username;
- (bool)removeToken:(NSString *)username;
- (void)postTweet:(NSString *)message completion:(void (^)(bool success)) completionHandler error:(void (^)(NSError * error)) errorHandler;
- (void)startPinAuth:(NSWindow *)window completion:(void (^)(bool success, NSDictionary *userinfo))completionHandler;
- (bool)logoutTwitter:(NSString *)username;
@end
