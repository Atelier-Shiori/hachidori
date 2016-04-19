//
//  Base64Category.m
//  Hachidori
//
//  Created by James M. on 8/8/10.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Base64Category.h"

@implementation NSString (Base64Category)

- (NSString *)base64Encoding
{
    // Use native methods
    NSData * plainData = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String;
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9){
        // Use newer method introduced in Mavericks
        base64String = [plainData base64EncodedStringWithOptions:0];
    }
    else{
        // Use deprecated base64Encoding method instead
        base64String = [plainData base64Encoding];
    }
    return base64String;
}

@end