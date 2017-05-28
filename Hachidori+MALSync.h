//
//  Hachidori+MALSync.h
//  Hachidori
//
//  Created by アナスタシア on 2016/04/17.
//
//

#import "Hachidori.h"

@interface Hachidori (MALSync)
- (BOOL)sync;
- (int)checkStatus;
- (BOOL)updatetitle;
- (BOOL)addtitle;
- (NSString *)getMALID;
@end
