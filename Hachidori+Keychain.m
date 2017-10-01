//
//  Hachidori+Keychain.m
//  Hachidori
//
//  Created by アナスタシア on 2015/09/30.
//  Copyright 2009-2018 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+Keychain.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import "Base64Category.h"

@implementation Hachidori (Keychain)
- (BOOL)checkmalaccount{
    // This method checks for any accounts that Hachidori can use
    NSArray * accounts = [SAMKeychain accountsForService:@"Hachidori - MyAnimeList"];
    if (accounts > 0) {
        //retrieve first valid account
        for (NSDictionary * account in accounts) {
            self.malusername = (NSString *)account[@"acct"];
            return true;
        }
    }
    self.malusername = @"";
    return false;
}
- (NSString *)getmalusername{
    if ([self checkmalaccount]) {
        return self.malusername;
    }
    return @"";
}
- (BOOL)storemalaccount:(NSString *)uname password:(NSString *)password{
    //Clear Account Information in the plist file if it hasn't been done already
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:@"Base64Token"];
    [defaults setObject:@"" forKey:@"Username"];
    self.malusername = uname;
    return [SAMKeychain setPassword:password forService:@"Hachidori - MyAnimeList" account:uname];
}
- (BOOL)removemalaccount{
    bool success = [SAMKeychain deletePasswordForService:@"Hachidori - MyAnimeList" account:self.username];
    // Set Username to blank
    self.malusername = @"";
    return success;
}
- (NSString *)getBase64{
    return [[NSString stringWithFormat:@"%@:%@", [self getmalusername], [SAMKeychain passwordForService:@"Hachidori - MyAnimeList" account:self.malusername]] base64Encoding];
}

- (int)checkMALCredentials {
    // Check if the credentialsvalid flag is not set to false/NO
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"credentialsvalid"]) {
        return 0;
    }
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"credentialscheckdate"] timeIntervalSinceNow] < 0) {
        // Check credentials
        //Set Login URL
        NSURL *url = [NSURL URLWithString:@"https://myanimelist.net/api/account/verify_credentials.xml"];
        EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
        //Ignore Cookies
        [request setUseCookies:NO];
        //Set Username and Password
        request.headers = @{@"Authorization": [NSString stringWithFormat:@"Basic %@", [self getBase64]]};
        //Verify Username/Password
        [request startRequest];
        // Check for errors
        NSError *error = [request getError];
        if ([request getStatusCode] == 200 && !error) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:60*60*24] forKey:@"credentialscheckdate"];
            NSLog(@"User credentials valid.");
            return 1;
        }
        else if ([request getStatusCode] == 204) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"credentialsvalid"];
            NSLog(@"ERROR: User credentials are invalid. Aborting MAL Sync...");
            return 0;
        }
        else {
            NSLog(@"Unable to check user credentials. Trying again later.");
            return 2;
        }
    }
    return 1;
    
    
}

@end
