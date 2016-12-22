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

@implementation LoginPref
@synthesize loginpanel;

- (instancetype)init
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
    logo.image = NSApp.applicationIconImage;
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
        NSDictionary * userdata = (NSDictionary *)ac.userData;
        loggedinuser.stringValue = [NSString stringWithFormat:@"%@", userdata[@"Username"]];
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
		if ( fieldusername.stringValue.length == 0) {
			//No Username Entered! Show error message
			[Utility showsheetmessage:@"Hachidori was unable to log you in since you didn't enter a username" explaination:@"Enter a valid username and try logging in again" window:self.view.window];
			[savebut setEnabled: YES];
		}
		else {
			if ( fieldpassword.stringValue.length == 0 ) {
				//No Password Entered! Show error message.
				[Utility showsheetmessage:@"Hachidori was unable to log you in since you didn't enter a password" explaination:@"Enter a valid password and try logging in again." window:self.view.window];
				[savebut setEnabled: YES];
			}
			else {
                    [self login:fieldusername.stringValue password:fieldpassword.stringValue];
                }
		}
       	}
}
-(void)login:(NSString *)username password:(NSString *)password{
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"Hachidori"
                                                              username:fieldusername.stringValue
                                                              password:fieldpassword.stringValue];
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      // Update your UI
                                                              [Utility showsheetmessage:@"Login Successful" explaination: @"Your account has been authenticated." window:self.view.window];
                                                      [self getFirstAccount].userData = @{@"Username" : fieldusername.stringValue, @"id" : [self retrieveUserID:fieldusername.stringValue]};
                                                      [clearbut setEnabled: YES];
                                                      loggedinuser.stringValue = username;
                                                      [loggedinview setHidden:NO];
                                                      [loginview setHidden:YES];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      NSError *error = (aNotification.userInfo)[NXOAuth2AccountStoreErrorKey];
                                                      // Do something with the error
                                                      //Login Failed, show error message
                                                      [Utility showsheetmessage:@"Hachidori was unable to log you in since you don't have the correct username and/or password." explaination:@"Check your username and password and try logging in again. If you recently changed your password, enter your new password and try again." window:self.view.window];
                                                      NSLog(@"%@",error);
                                                      [savebut setEnabled: YES];
                                                      savebut.keyEquivalent = @"\r";
                                                      [loggedinview setHidden:YES];
                                                      [loginview setHidden:NO];
                                                  }];
}
-(IBAction)registerhummingbird:(id)sender
{
	//Show Kitsu Registration Page
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
        [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
        [alert setMessageText:NSLocalizedString(@"Do you want to remove this account?",nil)];
        [alert setInformativeText:NSLocalizedString(@"Once you remove this account, you need to reauthenticate your account before you can use this application.",nil)];
        // Set Message type to Warning
        alert.alertStyle = NSWarningAlertStyle;
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            // Remove Oauth Account
            [[NXOAuth2AccountStore sharedStore]  removeAccount:[self getFirstAccount]];
            //Disable Clearbut
            [clearbut setEnabled: NO];
            [savebut setEnabled: YES];
            loggedinuser.stringValue = @"";
            [loggedinview setHidden:YES];
            [loginview setHidden:NO];
        }
    }
    else{
        [Utility showsheetmessage:@"Cannot Remove Account" explaination:@"Please turn off automatic scrobbling before removing this account." window:self.view.window];
    }
}
/*
 Reauthorization Panel
 */
-(IBAction)reauthorize:(id)sender{
    if (![appdelegate getisScrobbling] && ![appdelegate getisScrobblingActive]) {
        [NSApp beginSheet:self.loginpanel
           modalForWindow:self.view.window modalDelegate:self
           didEndSelector:@selector(reAuthPanelDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }
    else{
        [Utility showsheetmessage:@"Cannot Remove Account" explaination:@"Please turn off automatic scrobbling before removing this account." window:self.view.window];
    }
}
- (void)reAuthPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
        // Get Username
        NSString * username = [self getUsername];
        // Remove Oauth Account
        [[NXOAuth2AccountStore sharedStore]  removeAccount:[self getFirstAccount]];
        //Perform Login
        [self login:username password:passwordinput.stringValue];
    }
    //Reset and Close
    passwordinput.stringValue = @"";
    [invalidinput setHidden:YES];
    [self.loginpanel close];
}
-(IBAction)cancelreauthorization:(id)sender{
    [self.loginpanel orderOut:self];
    [NSApp endSheet:self.loginpanel returnCode:0];
    
}
-(IBAction)performreauthorization:(id)sender{
    if (passwordinput.stringValue.length == 0) {
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
    for (NXOAuth2Account *account in [NXOAuth2AccountStore sharedStore].accounts) {
        return account;
    };
    return nil;
}
-(NSString *)getUsername{
    for (NXOAuth2Account *account in [NXOAuth2AccountStore sharedStore].accounts) {
        NSDictionary * userdata = (NSDictionary *)account.userData;
        return userdata[@"username"];
    };
    return nil;
}
-(NSString *)retrieveUserID:(NSString *)username{
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/users?filter[name]=%@",username]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    // Get Information
    [request startoAuthRequest];
    NSDictionary * d;
    long statusCode = [request getStatusCode];
    if (statusCode == 200 || statusCode == 201 ) {
        //return Data
        NSError * jerror;
        d = [NSJSONSerialization JSONObjectWithData:[request getResponseData] options:kNilOptions error:&jerror];
        NSArray * tmp = d[@"data"];
        NSDictionary * uinfo = tmp[0];
        return [NSString stringWithFormat:@"%@",uinfo[@"id"]];
    }
    return @"";
}
@end
