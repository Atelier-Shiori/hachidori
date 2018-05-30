//
//  ClientConstants.m
//  Hachidori
//
//  Created by 天々座理世 on 2017/03/15.
//
//

#import "ClientConstants.h"

@implementation ClientConstants
    //
    // These constants specify the secret and client key
    // You can obtain them at
    //
    NSString *const kBaseURL = @"https://kitsu.io/api/";
    NSString *const kAuthURL = @"oauth/authorize";
    NSString *const kTokenURL = @"oauth/token";
    NSString *const ksecretkey = @"";
    NSString *const kclient = @"";

    //
    // These constants specify the secret and client key
    // You can obtain them at https://anilist.co/settings/developer/client/
    //
    NSString *const kanilistsecretkey =  @"";
    NSString *const kanilistclient = @"";

    // To obtain a Consumer Key and Consumer Secret for Twitter, go to:
    // https://apps.twitter.com/
    NSString *const kConsumerKey = @"";
    NSString *const kConsumerSecret = @"";
@end
