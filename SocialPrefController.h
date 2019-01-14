//
//  SocialPrefController.h
//  Hachidori
//
//  Created by 天々座理世 on 2018/01/24.
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
@class TwitterManager;
@class DiscordManager;

@interface SocialPrefController : NSViewController <MASPreferencesViewController>
@property (strong) TwitterManager *tw;
@property (strong) DiscordManager *dm;
- (instancetype)initWithTwitterManager:(TwitterManager *)tm;
@end
