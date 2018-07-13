//
//  AdvancedPrefController.h
//  Hachidori
//
//  Created by Tail Red on 3/21/15.
//
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
#import "AppDelegate.h"
#import "Hachidori.h"
@class PlexLogin;
@interface AdvancedPrefController : NSViewController <MASPreferencesViewController, NSTextFieldDelegate>
//Login Preferences
@property (strong) AppDelegate * appdelegate;
//Hachidori instance
@property (strong) Hachidori * haengine;
@property (strong) IBOutlet NSButton *kodicheck;

- (id)initwithAppDelegate:(AppDelegate *)adelegate;
@end
