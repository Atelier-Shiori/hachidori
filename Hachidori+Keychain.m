//
//  Hachidori+Keychain.m
//  Hachidori
//
//  Created by アナスタシア on 2015/09/30.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+Keychain.h"
#import "EasyNSURLConnection.h"
#import "Base64Category.h"

@implementation Hachidori (Keychain)
-(BOOL)checkaccount{
    // This method checks for any accounts that Hachidori can use
    NSArray * accounts = [SSKeychain accountsForService:@"Hachidori"];
    if (accounts > 0){
        //retrieve first valid account
        for (NSDictionary * account in accounts){
            if ([(NSString *)account[@"acct"] isEqualToString:@"htoken"]) {
                // Do not retrieve htoken account as username, it's meant to store the token from Hummingbird
                continue;
            }
            else{
                username = (NSString *)account[@"acct"];
                return true;
            }
        }
        
        
    }
    username = @"";
    return false;
}
-(int)generatetoken{
    // This method generates a new token from the current username and password from the Keychain
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/users/authenticate"]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Username
    [request addFormData:username forKey:@"username"];
    [request addFormData:[SSKeychain passwordForService:@"Hachidori" account:username] forKey:@"password"];
    [request setPostMethod:@"POST"];
    //Verify Username/Password
    [request startJSONFormRequest];
    // Check for errors
    NSError * error = [request getError];
    if ([request getStatusCode] == 201 && error == nil) {
        //Login successful
        bool success = [self storetoken:[[request getResponseDataString] stringByReplacingOccurrencesOfString:@"\"" withString:@""]];
        if (success) {
            return 201;
        }
        else{
            return 401;
        }
    }
    else{
        if (error.code == NSURLErrorNotConnectedToInternet) {
            return 0;
        }
        else{
            return 401;
        }
    }

}
-(NSString *)getusername{
    return username;
}
-(BOOL)storeaccount:(NSString *)uname password:(NSString *)password{
    //Clear Account Information in the plist file if it hasn't been done already
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:@"Token"];
    [defaults setObject:@"" forKey:@"Username"];
    return [SSKeychain setPassword:password forService:@"Hachidori" account:uname];
}
-(BOOL)removeaccount{
    bool success = [SSKeychain deletePasswordForService:@"Hachidori" account:username];
    // Set Username to blank
    username = @"";
    return success;
}
-(NSString *)gettoken{
    return [SSKeychain passwordForService:@"Hachidori" account:@"htoken"];
}
-(BOOL)storetoken:(NSString *)token{
    return [SSKeychain setPassword:token forService:@"Hachidori" account:@"htoken"];
}
-(BOOL)removetoken{
    return [SSKeychain deletePasswordForService:@"Hachidori" account:@"htoken"];
}
-(BOOL)checkmalaccount{
    // This method checks for any accounts that Hachidori can use
    NSArray * accounts = [SSKeychain accountsForService:@"Hachidori - MyAnimeList"];
    if (accounts > 0){
        //retrieve first valid account
        for (NSDictionary * account in accounts){
            malusername = (NSString *)account[@"acct"];
            return true;
        }
        
        
    }
    username = @"";
    return false;
}
-(NSString *)getmalusername{
    return malusername;
}
-(BOOL)storemalaccount:(NSString *)uname password:(NSString *)password{
    //Clear Account Information in the plist file if it hasn't been done already
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:@"Base64Token"];
    [defaults setObject:@"" forKey:@"Username"];
    return [SSKeychain setPassword:password forService:@"Hachidori - MyAnimeList" account:uname];
}
-(BOOL)removemalaccount{
    bool success = [SSKeychain deletePasswordForService:@"Hachidori - MyAnimeList" account:username];
    // Set Username to blank
    username = @"";
    return success;
}
-(NSString *)getBase64{
    return [[NSString stringWithFormat:@"%@:%@", [self getusername], [SSKeychain passwordForService:@"Hachidori - MyAnimeList" account:username]] base64Encoding];
}

@end
