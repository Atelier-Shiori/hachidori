//
//  PKCEGenerator.h
//  MAL Updater OS X
//
//  Created by 小鳥遊六花 on 4/25/18.
//

#import <Foundation/Foundation.h>

@interface PKCEGenerator : NSObject
+ (NSString *)createVerifierString;
+ (NSString *)generateCodeChallenge:(NSString *)challenge;
@end
