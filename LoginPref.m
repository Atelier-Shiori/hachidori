//
//  LoginPref.m
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import "LoginPref.h"
#import <EasyNSURLConnection/EasyNSURLConnection.h>
#import "Utility.h"
#import <AFNetworking/AFOAuth2Manager.h>
#import "ClientConstants.h"
#import "AppDelegate.h"
#import "Hachidori.h"

@implementation LoginPref
@synthesize loginpanel;

- (instancetype)init
{
	return [super initWithNibName:@"LoginView" bundle:nil];
}
- (id)initwithAppDelegate:(AppDelegate *)adelegate{
    
    _appdelegate = adelegate;
    return [super initWithNibName:@"LoginView" bundle:nil];
    
}
- (void)loadView{
    [super loadView];
    // Set Logo
    _logo.image = NSApp.applicationIconImage;
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

- (void)loadlogin
{
	// Load Username
    AFOAuthCredential *ac = [self getFirstAccount];
	if (ac) {
		[_clearbut setEnabled: YES];
		[_savebut setEnabled: NO];
        [_loggedinview setHidden:NO];
        [_loginview setHidden:YES];
        _loggedinuser.stringValue = [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] valueForKey:@"loggedinusername"]];
	}
	else {
		//Disable Clearbut
		[_clearbut setEnabled: NO];
		[_savebut setEnabled: YES];
	}
}
- (IBAction)startlogin:(id)sender
{
	{
		//Start Login Process
		//Disable Login Button
		[_savebut setEnabled: NO];
		[_savebut displayIfNeeded];
        if (![self canRetrieveUserID]) {
            //No Username Entered! Show error message
            [Utility showsheetmessage:@"Hachidori was unable to log you in since it can't retrieve the user ID of the associated account." explaination:@"Make sure the username is correct or try again." window:self.view.window];
            [_savebut setEnabled: YES];
        }
		else if (_fieldusername.stringValue.length == 0) {
			//No Username Entered! Show error message
			[Utility showsheetmessage:@"Hachidori was unable to log you in since you didn't enter a username" explaination:@"Enter a valid username and try logging in again" window:self.view.window];
			[_savebut setEnabled: YES];
		}
		else {
			if (_fieldpassword.stringValue.length == 0 ) {
				//No Password Entered! Show error message.
				[Utility showsheetmessage:@"Hachidori was unable to log you in since you didn't enter a password" explaination:@"Enter a valid password and try logging in again." window:self.view.window];
				[_savebut setEnabled: YES];
			}
			else {
                    [self login:_fieldusername.stringValue password:_fieldpassword.stringValue];
                }
		}
       	}
}
- (void)login:(NSString *)username password:(NSString *)password{
    NSURL *baseURL = [NSURL URLWithString:kBaseURL];
    AFOAuth2Manager *OAuth2Manager =
    [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                    clientID:kclient
                                      secret:ksecretkey];
        [OAuth2Manager authenticateUsingOAuthWithURLString:kTokenURL parameters:@{@"grant_type":@"password", @"username":username, @"password":password} success:^(AFOAuthCredential *credential) {
        // Update your UI
        [Utility showsheetmessage:@"Login Successful" explaination: @"Your account has been authenticated." window:self.view.window];
        [AFOAuthCredential storeCredential:credential
                                withIdentifier:@"Hachidori"];
        [[NSUserDefaults standardUserDefaults] setValue:_fieldusername.stringValue forKey:@"loggedinusername"];
        [[NSUserDefaults standardUserDefaults] setValue:[self retrieveUserID:_fieldusername.stringValue] forKey:@"UserID"];
        [_clearbut setEnabled: YES];
        _loggedinuser.stringValue = username;
        [_loggedinview setHidden:NO];
        [_loginview setHidden:YES];
        _fieldusername.stringValue = @"";
        _fieldpassword.stringValue = @"";
    }
    failure:^(NSError *error) {
                                                   NSLog(@"Error: %@", error);
                                                   // Do something with the error
                                                   //Login Failed, show error message
                                                   [Utility showsheetmessage:@"Hachidori was unable to log you in since you don't have the correct username and/or password." explaination:@"Check your username and password and try logging in again. If you recently changed your password, enter your new password and try again." window:self.view.window];
                                                   NSLog(@"%@",error);
                                                   [_savebut setEnabled: YES];
                                                   _savebut.keyEquivalent = @"\r";
                                                   [_loggedinview setHidden:YES];
                                                   [_loginview setHidden:NO];
                                               }];
   }
- (IBAction)registerhummingbird:(id)sender
{
	//Show Kitsu Registration Page
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://kitsu.io"]];
}
- (IBAction) showgettingstartedpage:(id)sender
{
    //Show Getting Started help page
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Getting-Started"]];
}
- (IBAction)clearlogin:(id)sender
{
    if (!_appdelegate.scrobbling && !_appdelegate.scrobbleractive) {
        // Set Up Prompt Message Window
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
        [alert setMessageText:NSLocalizedString(@"Do you want to remove this account?",nil)];
        [alert setInformativeText:NSLocalizedString(@"Once you remove this account, you need to reauthenticate your account before you can use this application.",nil)];
        // Set Message type to Warning
        alert.alertStyle = NSWarningAlertStyle;
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode== NSAlertFirstButtonReturn) {
                // Remove Oauth Account
                [AFOAuthCredential deleteCredentialWithIdentifier:@"Hachidori"];
                [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"loggedinusername"];
                [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserID"];
                //Disable Clearbut
                [_clearbut setEnabled: NO];
                [_savebut setEnabled: YES];
                _loggedinuser.stringValue = @"";
                [_loggedinview setHidden:YES];
                [_loginview setHidden:NO];
                [_appdelegate resetUI];
            }
        }];
    }
    else {
        [Utility showsheetmessage:@"Cannot Remove Account" explaination:@"Please turn off automatic scrobbling before removing this account." window:self.view.window];
    }
}
/*
 Reauthorization Panel
 */
- (IBAction)reauthorize:(id)sender{
    if (!_appdelegate.scrobbling && !_appdelegate.scrobbleractive) {
        [NSApp beginSheet:self.loginpanel
           modalForWindow:self.view.window modalDelegate:self
           didEndSelector:@selector(reAuthPanelDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }
    else {
        [Utility showsheetmessage:@"Cannot Remove Account" explaination:@"Please turn off automatic scrobbling before removing this account." window:self.view.window];
    }
}
- (void)reAuthPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
        // Get Username
        NSString * username = [self getUsername];
        // Remove Oauth Account
        [AFOAuthCredential deleteCredentialWithIdentifier:@"Hachidori"];
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"loggedinusername"];
        [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"UserID"];
        //Perform Login
        [self login:username password:_passwordinput.stringValue];
    }
    //Reset and Close
    _passwordinput.stringValue = @"";
    [_invalidinput setHidden:YES];
    [self.loginpanel close];
}
- (IBAction)cancelreauthorization:(id)sender{
    [self.loginpanel orderOut:self];
    [NSApp endSheet:self.loginpanel returnCode:0];
    
}
- (IBAction)performreauthorization:(id)sender{
    if (_passwordinput.stringValue.length == 0) {
        // No password, indicate it
        NSBeep();
        [_invalidinput setHidden:NO];
    }
    else {
        [_invalidinput setHidden:YES];
        [self.loginpanel orderOut:self];
        [NSApp endSheet:self.loginpanel returnCode:1];
    }
}
- (AFOAuthCredential *)getFirstAccount{
    return [AFOAuthCredential retrieveCredentialWithIdentifier:@"Hachidori"];
}
- (NSString *)getUsername{
    return [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] valueForKey:@"loggedinusername"]];
}
- (NSString *)retrieveUserID:(NSString *)username{
    //Set library/scrobble API
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/api/edge/users?filter[name]=%@",username]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    // Get Information
    [request startRequest];
    NSDictionary * d;
    long statusCode = [request getStatusCode];
    if (statusCode == 200 || statusCode == 201 ) {
        //return Data
        d = [request.response getResponseDataJsonParsed];
        NSArray * tmp = d[@"data"];
        if (tmp.count > 0) {
            NSDictionary * uinfo = tmp[0];
            return [NSString stringWithFormat:@"%@",uinfo[@"id"]];
        }
        return @"";
    }
    return @"";
}
- (bool)canRetrieveUserID {
    if ([self retrieveUserID:_fieldusername.stringValue].length > 0) {
        return true;
    }
    return false;
}
@end
