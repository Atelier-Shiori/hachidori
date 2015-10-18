//
//  Hachidori+Keychain.h
//  Hachidori
//
//  Created by アナスタシア on 2015/09/30.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "Hachidori.h"
#import "SSKeychain.h"

@interface Hachidori (Keychain)
-(BOOL)checkaccount;
-(int)generatetoken;
-(BOOL)storeaccount:(NSString *)uname password:(NSString *)password;
-(BOOL)removeaccount;
-(NSString *)getusername;
-(NSString *)gettoken;
-(BOOL)storetoken:(NSString *)token;
-(BOOL)removetoken;
@end
