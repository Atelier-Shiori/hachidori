//
//  Hachidori+Keychain.m
//  Hachidori
//
//  Created by アナスタシア on 2015/09/30.
//
//

#import "Hachidori+Keychain.h"
#import "EasyNSURLConnection.h"

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
				//Vertify Username/Password
    [request startFormRequest];
				// Check for errors
    NSError * error = [request getError];
    if ([request getStatusCode] == 201 && error == nil) {
        //Login successful
        bool success = [self storetoken:[[request getResponseDataString] stringByReplacingOccurrencesOfString:@"\"" withString:@""]];
        return 201;
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
    return [SSKeychain setPassword:password forService:@"Hachidori" account:uname];
}
-(BOOL)removeaccount{
    // Set Username to blank
    username = @"";
    return [SSKeychain deletePasswordForService:@"Hachidori" account:username];
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
@end
