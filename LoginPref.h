//
//  LoginPref.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
@class Hachidori;
@class AppDelegate;

@interface LoginPref : NSViewController <MASPreferencesViewController>
@property (strong) IBOutlet NSImageView * logo;
//Login Preferences
@property (strong) IBOutlet NSTextField * fieldusername;
@property (strong) IBOutlet NSTextField * fieldpassword;
@property (strong) IBOutlet NSButton * savebut;
@property (strong) IBOutlet NSButton * clearbut;
@property (strong) IBOutlet NSTextField * loggedinuser;
@property (strong) AppDelegate * appdelegate;
@property (strong) IBOutlet NSView * loginview;
@property (strong) IBOutlet NSView * loggedinview;
//Reauth Panel
@property (weak) NSWindow *loginpanel;
@property (strong) IBOutlet NSTextField * passwordinput;
@property (strong) IBOutlet NSImageView * invalidinput;
//Hachidori instance
@property (strong) Hachidori * haengine;

- (id)initwithAppDelegate:(AppDelegate *)adelegate;
- (IBAction)startlogin:(id)sender;
- (IBAction)clearlogin:(id)sender;
- (IBAction)registerhummingbird:(id)sender;
- (void)login:(NSString *)username password:(NSString *)password;
- (void)loadlogin;
@end
