//
//  AppDelegate+AppDelegate_Reachability.m
//  Hachidori
//
//  Created by Tail Red on 5/14/15.
//
//

#import "AppDelegate+AppDelegate_Reachability.h"

@implementation AppDelegate (AppDelegate_Reachability)
-(void)updateReachability{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enablekodiapi"]) {
        //Stop notifier first
        if (xmbcreach) {
            [xmbcreach stopNotifier];
        }
        xmbcreach = [Reachability reachabilityWithHostName:[[NSUserDefaults standardUserDefaults] objectForKey:@"kodiaddress"]];
        [xmbcreach startNotifier];
    }
    else{
        xmbcreach = nil;
    }
}
-(BOOL)getreachabilitystatus{
    return [xmbcreach isReachable];
}

@end
