//
//  AdvancedPrefController.h
//  Hachidori
//
//  Created by Tail Red on 3/21/15.
//
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"
#import "AppDelegate.h"
#import "Hachidori.h"
#import "Hachidori+Keychain.h"

@interface AdvancedPrefController : NSViewController <MASPreferencesViewController>{
    //Login Preferences
    IBOutlet NSTextField * fieldusername;
    IBOutlet NSTextField * fieldpassword;
    IBOutlet NSTextField * fieldmalapi;
    IBOutlet NSButton * savebut;
    IBOutlet NSButton * clearbut;
    IBOutlet NSTextField * loggedinuser;
    AppDelegate * appdelegate;
    IBOutlet NSView * loginview;
    IBOutlet NSView * loggedinview;
    //Hachidori instance
    Hachidori * haengine;
}
- (id)initwithAppDelegate:(AppDelegate *)adelegate;
-(IBAction)registermal:(id)sender;
-(IBAction)startlogin:(id)sender;
-(IBAction)clearlogin:(id)sender;
-(IBAction)resetMALAPI:(id)sender;
-(IBAction)testMALAPI:(id)sender;
@end
