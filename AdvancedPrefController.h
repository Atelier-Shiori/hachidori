//
//  AdvancedPrefController.h
//  Hachidori
//
//  Created by Tail Red on 3/21/15.
//
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
@class PlexLogin;
@interface AdvancedPrefController : NSViewController <MASPreferencesViewController, NSTextFieldDelegate>
@property (strong) IBOutlet NSButton *kodicheck;
@end
