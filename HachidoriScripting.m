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

-(id)performDefaultImplementation {

    // Implement your code logic (in this example, I'm just posting an internal notification)
    AppDelegate * delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[delegate getNowPlaying] options:0 error:&error];
    if (!jsonData) {}
    else{
        NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
        // Output JSON
        return JSONString;
    }
	return @"";
}
@end

@implementation ScriptingScrobbleNow
-(id)performDefaultImplementation {
    AppDelegate * delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [delegate firetimer:nil];
    return nil;
}
@end