//
//  AdvancedPrefController.m
//  Hachidori
//
//  Created by Tail Red on 3/21/15.
//
//

#import "AdvancedPrefController.h"
#import <EasyNSURLConnection/EasyNSURLConnectionClass.h>
#import "Utility.h"
#import "Base64Category.h"

@interface AdvancedPrefController ()

@end

@implementation AdvancedPrefController

- (instancetype)init
{
    return [super initWithNibName:@"AdvancedPrefController" bundle:nil];
}
- (id)initwithAppDelegate:(AppDelegate *)adelegate{
    appdelegate = adelegate;
    return [super initWithNibName:@"AdvancedPrefController" bundle:nil];
}
-(void)loadView{
    [super loadView];
    // Load Login State
    [self loadlogin];
}
-(void)loadlogin
{
    //Load Hachidori Engine Instance from AppDelegate
    haengine = appdelegate.getHachidoriInstance;
    
    // Load Username
    BOOL accountexists = [haengine checkmalaccount];
    if (accountexists) {
        [loginview setHidden:YES];
        loggedinuser.stringValue = [NSString stringWithFormat:@"%@", [haengine getmalusername]];
    }
    else {
        //Disable Clearbut
        [loggedinview setHidden:YES];
        [clearbut setEnabled: NO];
        [savebut setEnabled: YES];
    }
}
#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameAdvanced];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Advanced", @"Toolbar item name for the Advanced preference pane");
}
-(IBAction)getHelp:(id)sender{
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Advanced-Options"]];
}
-(IBAction)registermal:(id)sender{
    
}
-(IBAction)startlogin:(id)sender{
    {
        //Start Login Process
        //Disable Login Button
        [savebut setEnabled: NO];
        [savebut displayIfNeeded];
        if ( fieldusername.stringValue.length == 0) {
            //No Username Entered! Show error message
            [Utility showsheetmessage:@"Hachidori was unable to log you into your MyAnimeList account since you didn't enter a username" explaination:@"Enter a valid username and try logging in again" window:self.view.window];
            [savebut setEnabled: YES];
        }
        else {
            if ( fieldpassword.stringValue.length == 0 ) {
                //No Password Entered! Show error message.
                [Utility showsheetmessage:NSLocalizedString(@"Hachidori was unable to log you into your MyAnimeList account since you didn't enter a password",nil) explaination:NSLocalizedString(@"Enter a valid password and try logging in again.",nil) window:self.view.window];
                [savebut setEnabled: YES];
            }
            else {
                [self login:fieldusername.stringValue password:fieldpassword.stringValue];
            }
        }
    }
}
-(IBAction)clearlogin:(id)sender{
    if (![appdelegate getisScrobbling] && ![appdelegate getisScrobblingActive]) {
        // Set Up Prompt Message Window
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
        [alert setMessageText:NSLocalizedString(@"Do you want to log out?",nil)];
        [alert setInformativeText:NSLocalizedString(@"Once you logged out, you need to log back in before you can enable MyAnimeList sync functionality.",nil)];
        // Set Message type to Warning
        alert.alertStyle = NSWarningAlertStyle;
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            //Remove MyAnimeList account from keychain
            [haengine removemalaccount];
            //Disable Clearbut
            [clearbut setEnabled: NO];
            [savebut setEnabled: YES];
            loggedinuser.stringValue = @"";
            [loggedinview setHidden:YES];
            [loginview setHidden:NO];
            fieldusername.stringValue = @"";
            fieldpassword.stringValue = @"";
            // Disable MAL Sync
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MALSyncEnabled"];
        }
    }
    else{
        [Utility showsheetmessage:@"Cannot Logout" explaination:@"Please turn off automatic scrobbling before logging out." window:self.view.window];
    }
}
-(void)login:(NSString *)username password:(NSString *)password{
    //Set Login URL
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1/account/verify_credentials", [defaults objectForKey:@"MALAPIURL"]]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Set Username and Password
    [request addHeader:[NSString stringWithFormat:@"Basic %@", [[NSString stringWithFormat:@"%@:%@", username, password] base64Encoding]] forKey:@"Authorization"];
    //Verify Username/Password
    [request startRequest];
    // Check for errors
    NSError * error = [request getError];
    if ([request getStatusCode] == 200 && error == nil) {
        //Login successful
        [Utility showsheetmessage:@"Login Successful" explaination: @"Login is successful." window:self.view.window];
        // Store account in login keychain
        [haengine storemalaccount:fieldusername.stringValue password:fieldpassword.stringValue];
        [clearbut setEnabled: YES];
        loggedinuser.stringValue = username;
        [loggedinview setHidden:NO];
        [loginview setHidden:YES];
    }
    else{
        if (error.code == NSURLErrorNotConnectedToInternet) {
            [Utility showsheetmessage:@"Hachidori was unable to log you into your MyAnimeList account since you are not connected to the internet" explaination:@"Check your internet connection and try again." window:self.view.window];
            [savebut setEnabled: YES];
            savebut.keyEquivalent = @"\r";
        }
        else{
            //Login Failed, show error message
            [Utility showsheetmessage:@"Hachidori was unable to log you into your MyAnimeList account since you don't have the correct username and/or password." explaination:@"Check your username and password and try logging in again. If you recently changed your password, enter your new password and try again." window:self.view.window];
            [savebut setEnabled: YES];
            savebut.keyEquivalent = @"\r";
        }
    }
}

-(IBAction)resetMALAPI:(id)sender{
    //Reset Unofficial MAL API URL
    fieldmalapi.stringValue = @"https://malapi.ateliershiori.moe";
    // Generate API Key
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults] ;
    [defaults setObject:fieldmalapi.stringValue forKey:@"MALAPIURL"];
}
-(IBAction)testMALAPI:(id)sender{
    //Load API URL
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set URL
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1/animelist/chikorita157", [defaults objectForKey:@"MALAPIURL"]]];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Test API
    [request startRequest];
    // Get Status Code
    long statusCode = [request getStatusCode];
    switch (statusCode) {
        case 200:
            [Utility showsheetmessage:@"API Test Successful" explaination:[NSString stringWithFormat:@"HTTP Code: %li", statusCode] window: self.view.window];
            break;
        default:
            [Utility showsheetmessage:@"API Test Unsuccessful" explaination:[NSString stringWithFormat:@"HTTP Code: %li", statusCode] window:self.view.window];
            break;
    }

}
-(IBAction)addLicense:(id)sender{
    [appdelegate enterDonationKey];

}
@end
