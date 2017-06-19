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
#import "Hachidori+Keychain.h"

@interface AdvancedPrefController : NSViewController <MASPreferencesViewController>
//Login Preferences
@property (strong) IBOutlet NSTextField * fieldusername;
@property (strong) IBOutlet NSTextField * fieldpassword;
@property (strong) IBOutlet NSTextField * fieldmalapi;
@property (strong) IBOutlet NSButton * savebut;
@property (strong) IBOutlet NSButton * clearbut;
@property (strong) IBOutlet NSTextField * loggedinuser;
@property (strong) IBOutlet NSButton *testapibtn;
@property (strong) AppDelegate * appdelegate;
@property (strong) IBOutlet NSView * loginview;
@property (strong) IBOutlet NSView * loggedinview;
//Hachidori instance
@property (strong) Hachidori * haengine;
@property (strong) IBOutlet NSButton *kodicheck;
- (id)initwithAppDelegate:(AppDelegate *)adelegate;
- (IBAction)registermal:(id)sender;
- (IBAction)startlogin:(id)sender;
- (IBAction)clearlogin:(id)sender;
- (IBAction)resetMALAPI:(id)sender;
- (IBAction)testMALAPI:(id)sender;
@end
