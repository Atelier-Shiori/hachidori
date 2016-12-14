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
    /*
    //Load Hachidori Engine Instance from AppDelegate
    haengine = appdelegate.getHachidoriInstance;
    
	// Load Username
    BOOL * accountexists = [haengine checkaccount];
	if (accountexists) {
		[clearbut setEnabled: YES];
		[savebut setEnabled: NO];
        [loggedinview setHidden:NO];
        [loginview setHidden:YES];
        [loggedinuser setStringValue:[NSString stringWithFormat:@"%@", [haengine getusername]]];
	}
	else {
		//Disable Clearbut
		[clearbut setEnabled: NO];
		[savebut setEnabled: YES];
	}*/
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
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                      // Do something with the error
                                                      //Login Failed, show error message
                                                      [Utility showsheetmessage:@"Hachidori was unable to log you in since you don't have the correct username and/or password." explaination:@"Check your username and password and try logging in again. If you recently changed your password, enter your new password and try again." window:[[self view] window]];
                                                      [savebut setEnabled: YES];
                                                      [savebut setKeyEquivalent:@"\r"];
                                                  }];

    /*//Set Login URL
				NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://hummingbird.me/api/v1/users/authenticate"]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
				//Ignore Cookies
				[request setUseCookies:NO];
				//Set Username
    [request addFormData:username forKey:@"username"];
    [request addFormData:password forKey:@"password"];
    [request setPostMethod:@"POST"];
				//Vertify Username/Password
    [request startJSONFormRequest];
				// Check for errors
    NSError * error = [request getError];
    if ([request getStatusCode] == 201 && error == nil) {
        //Login successful
        [Utility showsheetmessage:@"Login Successful" explaination: @"Login Token has been recieved." window:[[self view] window]];
        // Store auth token in Keychain
        bool success = [haengine storetoken:[[request getResponseDataString] stringByReplacingOccurrencesOfString:@"\"" withString:@""]];
        //Store Account in Keychain
        [haengine storeaccount:username password:password];
        [clearbut setEnabled: YES];
        [loggedinuser setStringValue:username];
        [loggedinview setHidden:NO];
        [loginview setHidden:YES];
    }
    else{
        if (error.code == NSURLErrorNotConnectedToInternet) {
            [Utility showsheetmessage:@"Hachidori was unable to log you in since you are not connected to the internet" explaination:@"Check your internet connection and try again." window:[[self view] window]];
            [savebut setEnabled: YES];
            [savebut setKeyEquivalent:@"\r"];
        }
        else{

        }
    }

    //release
    request = nil;
    url = nil;
*/
}
-(IBAction)registerhummingbird:(id)sender
{
	//Show Hummingbird Registration Page
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://hummingbird.me/users/sign_up"]];
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
        [alert setMessageText:@"Do you want to log out?"];
        [alert setInformativeText:@"Once you logged out, you need to log back in before you can use this application."];
        // Set Message type to Warning
        [alert setAlertStyle:NSWarningAlertStyle];
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            // Remove token
            [haengine removetoken];
            // Remove account from Keychain
            [haengine removeaccount];
            //Disable Clearbut
            [clearbut setEnabled: NO];
            [savebut setEnabled: YES];
            [loggedinuser setStringValue:@""];
            [loggedinview setHidden:YES];
            [loginview setHidden:NO];
        }
    }
    else{
        [Utility showsheetmessage:@"Cannot Logout" explaination:@"Please turn off automatic scrobbling before logging out." window:[[self view] window]];
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
        [Utility showsheetmessage:@"Cannot Logout" explaination:@"Please turn off automatic scrobbling before reauthorizing." window:[[self view] window]];
    }
}
- (void)reAuthPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
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
@end
