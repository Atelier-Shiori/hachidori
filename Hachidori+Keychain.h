//
//  Hachidori+Keychain.h
//  Hachidori
//
//  Created by アナスタシア on 2015/09/30.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"
#import <SAMKeychain/SAMKeychain.h>

@interface Hachidori (Keychain)
- (BOOL)checkmalaccount;
- (BOOL)storemalaccount:(NSString *)uname password:(NSString *)password;
- (BOOL)removemalaccount;
- (NSString *)getmalusername;
- (NSString *)getBase64;
- (int)checkMALCredentials;
@end

