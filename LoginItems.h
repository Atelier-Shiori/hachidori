//
//  LoginItems.h
//  Hachidori
//
//  Created by 天々座理世 on 2017/04/02.
//
//

#import <Foundation/Foundation.h>

@interface LoginItems : NSObject
+ (BOOL)isLaunchAtStartup;
+ (void)toggleLaunchAtStartup;
+ (LSSharedFileListItemRef)itemRefInLoginItems;
@end
