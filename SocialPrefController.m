//
//  SocialPrefController.m
//  Hachidori
//
//  Created by 天々座理世 on 2018/01/24.
//

#import "SocialPrefController.h"
#import <TwitterManagerKit/TwitterManagerKit.h>
#import "DiscordManager.h"

@interface SocialPrefController ()
@property (strong) IBOutlet NSTextField *usernamefield;
@property (strong) IBOutlet NSButton *logoutbtn;
@property (strong) IBOutlet NSButton *authenticatebtn;
@property (strong) IBOutlet NSButton *twonscrobblecheckbox;

@end

@implementation SocialPrefController
- (id)init {
    return [super initWithNibName:@"SocialPrefController" bundle:nil];
}

- (id)initWithTwitterManager:(TwitterManager *)tm withDiscordManager:(DiscordManager *)dm{
    self.tw = tm;
    self.dm = dm;
    return [self init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self checklogin];
}
- (void)checklogin {
    NSDictionary *userinfo = [_tw getFirstAccount];
    if (userinfo) {
        _usernamefield.stringValue = userinfo[@"screenname"];
        _authenticatebtn.hidden = true;
        _logoutbtn.hidden = false;
        _twonscrobblecheckbox.enabled = true;
    }
    else {
        _usernamefield.stringValue = @"To post updates to Twitter, authenticate your account.";
        _authenticatebtn.hidden = false;
        _logoutbtn.hidden = true;
        _twonscrobblecheckbox.enabled = false;
    }
}

- (IBAction)authenticate:(id)sender {
    [_tw startPinAuth:self.view.window completion:^(bool success, NSDictionary *userinfo) {
        if (success) {
            [self checklogin];
        }
    }];
}

- (IBAction)logout:(id)sender {
    // Set Up Prompt Message Window
    NSAlert *alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    alert.messageText = @"Do you want to log out?";
    alert.informativeText = @"Once you logged out, you need to authenticate your Twitter account to post Scrobble updates to Twitter.";
    // Set Message type to Warning
    alert.alertStyle = NSWarningAlertStyle;
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode== NSAlertFirstButtonReturn) {
            if ([_tw logoutTwitter:_usernamefield.stringValue]) {
                [self checklogin];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"tweetonscrobble"];
            }
        }
    }];
}

- (IBAction)togglepresence:(id)sender {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"usediscordrichpresence"]) {
        [_dm startDiscordRPC];
    }
    else {
        [_dm removePresence];
        [_dm shutdownDiscordRPC];
    }
}

#pragma mark MASPreferences
- (NSString *)identifier
{
    return @"SocialPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameUserAccounts];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Social Accounts", @"Toolbar item name for the Social Accounts preference pane");
}
@end
