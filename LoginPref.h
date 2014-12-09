//
//  LoginPref.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"
#import "AppDelegate.h"

@interface LoginPref : NSViewController <MASPreferencesViewController> {
	//Login Preferences
	IBOutlet NSTextField * fieldusername;
	IBOutlet NSTextField * fieldpassword;
	IBOutlet NSButton * savebut;
	IBOutlet NSButton * clearbut;
    IBOutlet NSTextField * loggedinuser;
    AppDelegate * appdelegate;
    IBOutlet NSView * loginview;
    IBOutlet NSView * loggedinview;
}
- (id)initwithAppDelegate:(AppDelegate *)adelegate;
-(IBAction)startlogin:(id)sender;
-(IBAction)clearlogin:(id)sender;
-(void)showsheetmessage:(NSString *)message
		   explaination:(NSString *)explaination;
-(IBAction)registerhummingbird:(id)sender;
-(void)loadlogin;
@end
