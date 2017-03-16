//
//  LoginPref.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
#import "AppDelegate.h"
#import "Hachidori.h"

@interface LoginPref : NSViewController <MASPreferencesViewController> {
    IBOutlet NSImageView * logo;
	//Login Preferences
	IBOutlet NSTextField * fieldusername;
	IBOutlet NSTextField * fieldpassword;
	IBOutlet NSButton * savebut;
	IBOutlet NSButton * clearbut;
    IBOutlet NSTextField * loggedinuser;
    AppDelegate * appdelegate;
    IBOutlet NSView * loginview;
    IBOutlet NSView * loggedinview;
    //Reauthorize Panel
    __unsafe_unretained NSWindow *loginpanel;
    IBOutlet NSTextField * passwordinput;
    IBOutlet NSImageView * invalidinput;
    //Hachidori instance
    Hachidori * haengine;
}
@property (assign) IBOutlet NSWindow *loginpanel;
- (id)initwithAppDelegate:(AppDelegate *)adelegate;
-(IBAction)startlogin:(id)sender;
-(IBAction)clearlogin:(id)sender;
-(IBAction)registerhummingbird:(id)sender;
-(void)login:(NSString *)username password:(NSString *)password;
-(void)loadlogin;
@end
