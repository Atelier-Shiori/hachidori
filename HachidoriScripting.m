//
//  HachidoriScripting.m
//  Hachidori
//
//  Created by Tail Red on 6/19/15.
//  Copyright 2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "HachidoriScripting.h"
#import "AppDelegate.h"

@implementation ScriptingGetStatus
// AppleScript command for GetStatus
-(id)performDefaultImplementation {
    AppDelegate * delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[delegate getNowPlaying] options:0 error:&error];
    if (!jsonData) {}
    else{
        NSString *JSONString = [[NSString alloc] initWithBytes:jsonData.bytes length:jsonData.length encoding:NSUTF8StringEncoding];
        // Output JSON
        return JSONString;
    }
	return @"";
}
@end

@implementation ScriptingScrobbleNow
// AppleScript command for ScrobbleNow
-(id)performDefaultImplementation {
    AppDelegate * delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    [delegate updatenow:nil];
    return nil;
}
@end

@implementation ScriptingToggleAutoScrobble
// AppleScript command for ToggleAutoScrobble
-(id)performDefaultImplementation{
     AppDelegate * delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    [delegate toggletimer:nil];
    return nil;
}
@end
