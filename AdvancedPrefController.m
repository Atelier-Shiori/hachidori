//
//  AdvancedPrefController.m
//  Hachidori
//
//  Created by Tail Red on 3/21/15.
//
//

#import "AdvancedPrefController.h"
#import <AFNetworking/AFNetworking.h>
#import "Utility.h"
#import "Base64Category.h"
#import <DetectionKit/DetectionKit.h>

@interface AdvancedPrefController ()

@end

@implementation AdvancedPrefController

@synthesize fieldusername;
@synthesize fieldpassword;
@synthesize fieldmalapi;
@synthesize savebut;
@synthesize clearbut;
@synthesize loggedinuser;
@synthesize testapibtn;
@synthesize appdelegate;
@synthesize loginview;
@synthesize loggedinview;
@synthesize haengine;

- (instancetype)init {
    return [super initWithNibName:@"AdvancedPrefController" bundle:nil];
}

- (id)initwithAppDelegate:(AppDelegate *)adelegate {
    appdelegate = adelegate;
    return [super initWithNibName:@"AdvancedPrefController" bundle:nil];
}

- (void)loadView {
    [super loadView];
    // Load Login State
    [self loadlogin];
}
- (void)loadlogin {
    //Load Hachidori Engine Instance from AppDelegate
    haengine = appdelegate.getHachidoriInstance;
    
    // Load Username
    BOOL accountexists = [haengine checkmalaccount];
    if (accountexists) {
        loginview.hidden = YES;
        loggedinuser.stringValue = [NSString stringWithFormat:@"%@", [haengine getmalusername]];
    }
    else {
        //Disable Clearbut
        loggedinview.hidden = YES;
        clearbut.enabled = NO;
        savebut.enabled = YES;
    }
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier {
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameAdvanced];
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"Advanced", @"Toolbar item name for the Advanced preference pane");
}
- (IBAction)getHelp:(id)sender {
    //Show Help
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/chikorita157/hachidori/wiki/Advanced-Options"]];
}
- (IBAction)registermal:(id)sender {
    
}
- (IBAction)startlogin:(id)sender {
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
- (IBAction)clearlogin:(id)sender {
    if (!appdelegate.scrobbling && !appdelegate.scrobbleractive) {
        // Set Up Prompt Message Window
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
        [alert setMessageText:NSLocalizedString(@"Do you want to log out?",nil)];
        [alert setInformativeText:NSLocalizedString(@"Once you logged out, you need to log back in before you can enable MyAnimeList sync functionality.",nil)];
        // Set Message type to Warning
        alert.alertStyle = NSWarningAlertStyle;
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode== NSAlertFirstButtonReturn) {
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
        }];
    }
    else {
        [Utility showsheetmessage:@"Cannot Logout" explaination:@"Please turn off automatic scrobbling before logging out." window:self.view.window];
    }
}
- (void)login:(NSString *)username password:(NSString *)password {
    [savebut setEnabled:NO];
    //Set Login URL
    AFHTTPSessionManager *manager = [Utility manager];
    manager.responseSerializer = [Utility httpresponseserializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@", [[NSString stringWithFormat:@"%@:%@", username, password] base64Encoding]] forHTTPHeaderField:@"Authorization"];
    [manager GET:@"https://myanimelist.net/api/account/verify_credentials.xml" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        //Login successful
        [Utility showsheetmessage:@"Login Successful" explaination: @"Login is successful." window:self.view.window];
        // Store account in login keychain
        [haengine storemalaccount:fieldusername.stringValue password:fieldpassword.stringValue];
        // Set the date to Verify Credentials
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:60*60*24] forKey:@"credentialscheckdate"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"credentialsvalid"];
        [clearbut setEnabled: YES];
        loggedinuser.stringValue = username;
        [loggedinview setHidden:NO];
        [loginview setHidden:YES];
        [savebut setEnabled:YES];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if ([[error.userInfo valueForKey:@"NSLocalizedDescription"] isEqualToString:@"Request failed: unauthorized (401)"]) {
            //Login Failed, show error message
            [Utility showsheetmessage:@"Hachidori was unable to log you into your MyAnimeList account since you don't have the correct username and/or password." explaination:@"Check your username and password and try logging in again. If you recently changed your password, enter your new password and try again." window:self.view.window];
            [savebut setEnabled: YES];
            savebut.keyEquivalent = @"\r";
        }
        else if ([[error.userInfo valueForKey:@"NSLocalizedDescription"] isEqualToString:@"Request failed: forbidden (403)"]) {
            [Utility showsheetmessage:@"Hachidori was unable to log you into your MyAnimeList account since you had too many login attempts." explaination:@"Check your username and password and try logging in again after several hours." window:self.view.window];
            [savebut setEnabled: YES];
            savebut.keyEquivalent = @"\r";
        }
        else {
            [Utility showsheetmessage:@"Hachidori was unable to log you into your MyAnimeList account since you are not connected to the internet" explaination:@"Check your internet connection and try again." window:self.view.window];
            [savebut setEnabled: YES];
            savebut.keyEquivalent = @"\r";
        }
    }];
 }

- (IBAction)resetMALAPI:(id)sender {
    //Reset Unofficial MAL API URL
    fieldmalapi.stringValue = @"https://malapi.malupdaterosx.moe";
    // Set MAL API URL in settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults] ;
    [defaults setObject:fieldmalapi.stringValue forKey:@"MALAPIURL"];
}
- (IBAction)testMALAPI:(id)sender {
    [testapibtn setEnabled:NO];
    //Load API URL
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    AFHTTPSessionManager *manager = [Utility manager];
    [manager GET:[NSString stringWithFormat:@"%@/1/animelist/chikorita157", [defaults objectForKey:@"MALAPIURL"]] parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        [Utility showsheetmessage:@"API Test Successful" explaination:@"MAL API is functional." window: self.view.window];
            [testapibtn setEnabled:YES];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        [Utility showsheetmessage:@"API Test Unsuccessful" explaination:[NSString stringWithFormat:@"Error: %@", error] window:self.view.window];
            [testapibtn setEnabled:YES];
    }];

}
- (IBAction)addLicense:(id)sender {
    [appdelegate enterDonationKey];

}
- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField * textfield = notification.object;
    if ([textfield.identifier isEqualToString:@"kodiaddress"]) {
        [appdelegate.haengine.detection setKodiReachAddress:textfield.stringValue];
    }
    
}
- (IBAction)setKodiReach:(id)sender {
    if (_kodicheck.state == 0) {
        // Turn off reachability notification for Kodi
        [appdelegate.haengine.detection setKodiReach:false];
    }
    else {
        // Turn on reachability notification for Kodi
        [appdelegate.haengine.detection setKodiReach:true];
    }
}

@end
