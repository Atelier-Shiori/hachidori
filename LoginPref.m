//
//  LoginPref.m
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "LoginPref.h"
#import "EasyNSURLConnection.h"
#import "Utility.h"
#import "Hachidori+Keychain.h"

@implementation LoginPref
@synthesize loginpanel;

- (id)init
{
	return [super initWithNibName:@"LoginView" bundle:nil];
}
- (id)initwithAppDelegate:(AppDelegate *)adelegate{
    
    appdelegate = adelegate;
    return [super initWithNibName:@"LoginView" bundle:nil];
    
}
-(void)loadView{
    [super loadView];
    // Set Logo
    [logo setImage:[NSApp applicationIconImage]];
    // Load Login State
	[self loadlogin];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"LoginPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameUser];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Login", @"Toolbar item name for the Login preference pane");
}

-(void)loadlogin
{
	// Load Username
    NXOAuth2Account *ac = [self getFirstAccount];
	if (ac) {
		[clearbut setEnabled: YES];
		[savebut setEnabled: NO];
        [loggedinview setHidden:NO];
        [loginview setHidden:YES];
        NSDictionary * userdata = (NSDictionary *)[ac userData];
        [loggedinuser setStringValue:[NSString stringWithFormat:@"%@", userdata[@"Username"]]];
	}
	else {
		//Disable Clearbut
		[clearbut setEnabled: NO];
		[savebut setEnabled: YES];
	}
}
-(IBAction)startlogin:(id)sender
{
	{
		//Start Login Process
		//Disable Login Button
		[savebut setEnabled: NO];
		[savebut displayIfNeeded];
		if ( [[fieldusername stringValue] length] == 0) {
			//No Username Entered! Show error message
			[Utility showsheetmessage:@"Hachidori was unable to log you in since you didn't enter a username" explaination:@"Enter a valid username and try logging in again" window:[[self view] window]];
			[savebut setEnabled: YES];
		}
		else {
			if ( [[fieldpassword stringValue] length] == 0 ) {
				//No Password Entered! Show error message.
				[Utility showsheetmessage:@"Hachidori was unable to log you in since you didn't enter a password" explaination:@"Enter a valid password and try logging in again." window:[[self view] window]];
				[savebut setEnabled: YES];
			}
			else {
                    [self login:[fieldusername stringValue] password:[fieldpassword stringValue]];
                }
		}
       	}
}
-(void)login:(NSString *)username password:(NSString *)password{
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"Hachidori"
                                                              username:[fieldusername stringValue]
                                                              password:[fieldpassword stringValue]];
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      // Update your UI
                                                              [Utility showsheetmessage:@"Login Successful" explaination: @"Login Token has been recieved." window:[[self view] window]];
                                                      [[self getFirstAccount] setUserData:@{@"Username" : [fieldusername stringValue]}];
                                                      [clearbut setEnabled: YES];
                                                      [loggedinuser setStringValue:username];
                                                      [loggedinview setHidden:NO];
                                                      [loginview setHidden:YES];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                      // Do something with the error
                                                      //Login Failed, show error message
                                                      [Utility showsheetmessage:@"Hachidori was unable to log you in since you don't have the correct username and/or password." explaination:@"Check your username and password and try logging in again. If you recently changed your password, enter your new password and try again." window:[[self view] window]];
                                                      NSLog(@"%@",error);
                                                      [savebut setEnabled: YES];
                                                      [savebut setKeyEquivalent:@"\r"];
                                                      [loggedinview setHidden:YES];
                                                      [loginview setHidden:NO];
                                                  }];
}
-(IBAction)registerhummingbird:(id)sender
{
	//Show Kiysu Registration Page
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://kitsu.io"]];
}
-(IBAction) showgettingstartedpage:(id)sender
{
    //Show Getting Started help page
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Getting-Started"]];
}
-(IBAction)clearlogin:(id)sender
{
    if (![appdelegate getisScrobbling] && ![appdelegate getisScrobblingActive]) {
        // Set Up Prompt Message Window
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Do you want to remove this account?"];
        [alert setInformativeText:@"Once you remove this account, you need to reauthenticate your account before you can use this application."];
        // Set Message type to Warning
        [alert setAlertStyle:NSWarningAlertStyle];
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            // Remove Oauth Account
            [[NXOAuth2AccountStore sharedStore]  removeAccount:[self getFirstAccount]];
            //Disable Clearbut
            [clearbut setEnabled: NO];
            [savebut setEnabled: YES];
            [loggedinuser setStringValue:@""];
            [loggedinview setHidden:YES];
            [loginview setHidden:NO];
        }
    }
    else{
        [Utility showsheetmessage:@"Cannot Remove Account" explaination:@"Please turn off automatic scrobbling before removing this account." window:[[self view] window]];
    }
}
/*
 Reauthorization Panel
 */
-(IBAction)reauthorize:(id)sender{
    if (![appdelegate getisScrobbling] && ![appdelegate getisScrobblingActive]) {
        [NSApp beginSheet:self.loginpanel
           modalForWindow:[[self view] window] modalDelegate:self
           didEndSelector:@selector(reAuthPanelDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }
    else{
        [Utility showsheetmessage:@"Cannot Remove Account" explaination:@"Please turn off automatic scrobbling before removing this account." window:[[self view] window]];
    }
}
- (void)reAuthPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
        // Remove Oauth Account
        [[NXOAuth2AccountStore sharedStore]  removeAccount:[self getFirstAccount]];
        //Perform Login
        [self login:[NSString stringWithFormat:@"%@", [haengine getusername]] password:[passwordinput stringValue]];
    }
    //Reset and Close
    [passwordinput setStringValue:@""];
    [invalidinput setHidden:YES];
    [self.loginpanel close];
}
-(IBAction)cancelreauthorization:(id)sender{
    [self.loginpanel orderOut:self];
    [NSApp endSheet:self.loginpanel returnCode:0];
    
}
-(IBAction)performreauthorization:(id)sender{
    if ([[passwordinput stringValue] length] == 0) {
        // No password, indicate it
        NSBeep();
        [invalidinput setHidden:NO];
    }
    else{
        [invalidinput setHidden:YES];
        [self.loginpanel orderOut:self];
        [NSApp endSheet:self.loginpanel returnCode:1];
    }
}
-(NXOAuth2Account *)getFirstAccount{
    for (NXOAuth2Account *account in [[NXOAuth2AccountStore sharedStore] accounts]) {
        return account;
    };
    return nil;
}
@end
