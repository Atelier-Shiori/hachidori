//
//  Hachidori+Keychain.m
//  Hachidori
//
//  Created by アナスタシア on 2015/09/30.
//  Copyright 2009-2018 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import "Hachidori+Keychain.h"
#import <AFNetworking/AFNetworking.h>
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
        //Set Username and Password
        [self.malcredmanager.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@", [self getBase64]] forHTTPHeaderField:@"Authorization"];
        //Verify Username/Password
        NSURLSessionDataTask *task;
        NSError *error;
        id responseObject = [self.malcredmanager syncGET:@"https://myanimelist.net/api/account/verify_credentials.xml" parameters:nil task:&task error:&error];
        long statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
        if (statusCode == 200 && !error) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:60*60*24] forKey:@"credentialscheckdate"];
            NSLog(@"User credentials valid.");
            return 1;
        }
        else if (statusCode == 204 || statusCode == 401) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"credentialsvalid"];
            NSLog(@"ERROR: User credentials are invalid. Aborting MAL Sync...");
            return 0;
        }
        else if (statusCode == 403) {
            NSLog(@"ERROR: Too many login attempts. Try again later.");
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
