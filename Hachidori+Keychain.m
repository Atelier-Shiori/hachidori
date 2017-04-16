//
//  Hachidori+Keychain.m
//  Hachidori
//
//  Created by アナスタシア on 2015/09/30.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+Keychain.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import "Base64Category.h"

@implementation Hachidori (Keychain)
-(BOOL)checkmalaccount{
    // This method checks for any accounts that Hachidori can use
    NSArray * accounts = [SSKeychain accountsForService:@"Hachidori - MyAnimeList"];
    if (accounts > 0) {
        //retrieve first valid account
        for (NSDictionary * account in accounts) {
            malusername = (NSString *)account[@"acct"];
            return true;
        }
        
        
    }
    malusername = @"";
    return false;
}
-(NSString *)getmalusername{
    if ([self checkmalaccount]) {
        return malusername;
    }
    return @"";
}
-(BOOL)storemalaccount:(NSString *)uname password:(NSString *)password{
    //Clear Account Information in the plist file if it hasn't been done already
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:@"Base64Token"];
    [defaults setObject:@"" forKey:@"Username"];
    malusername = uname;
    return [SSKeychain setPassword:password forService:@"Hachidori - MyAnimeList" account:uname];
}
-(BOOL)removemalaccount{
    bool success = [SSKeychain deletePasswordForService:@"Hachidori - MyAnimeList" account:username];
    // Set Username to blank
    malusername = @"";
    return success;
}
-(NSString *)getBase64{
    return [[NSString stringWithFormat:@"%@:%@", [self getmalusername], [SSKeychain passwordForService:@"Hachidori - MyAnimeList" account:malusername]] base64Encoding];
}

@end
