//
//  PlexPrefs.m
//  Hachidori
//
//  Created by 桐間紗路 on 2017/07/11.
//
//

#import "PlexPrefs.h"
#import <DetectionKit/DetectionKit.h>
#import "PlexLogin.h"
#import "Hachidori.h"

@interface PlexPrefs ()
@property (strong) IBOutlet NSButton *plexlogin;
@property (strong) IBOutlet NSButton *plexlogout;
@property (strong) IBOutlet NSButton *plexcheck;
@property (strong) IBOutlet NSTextField *plexusernamelabel;
@property (strong) PlexLogin *plexloginwindowcontroller;
@end

@implementation PlexPrefs
@synthesize plexlogin;
@synthesize plexlogout;
@synthesize plexusernamelabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    // Load Login State for Plex
    [self loadplexlogin];
}
- (instancetype)init {
    return [super initWithNibName:@"PlexPrefs" bundle:nil];
}
#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"PlexMediaServerPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"plex"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Plex", @"Toolbar item name for the Plex Media Server preference pane");
}
#pragma mark -
#pragma mark Plex Media Server Detection Prefs
- (void)loadplexlogin {
    NSString *username = [PlexAuth checkplexaccount];
    if (username.length > 0) {
        plexusernamelabel.stringValue = [NSString stringWithFormat:@"Logged in as: %@", username];
        plexlogin.hidden = YES;
        plexlogout.hidden = NO;
    }
    else {
        plexusernamelabel.stringValue = @"Not logged in.";
        plexlogin.hidden = NO;
        plexlogout.hidden = YES;
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField * textfield = notification.object;
    [NSNotificationCenter.defaultCenter postNotificationName:@"PlexAddressChanged" object:textfield.stringValue];
}

- (IBAction)setPlexReach:(id)sender {
    [NSNotificationCenter.defaultCenter postNotificationName:@"PlexToggled" object:nil];
}

- (IBAction)plexlogin:(id)sender {
    if (!_plexloginwindowcontroller) {
        _plexloginwindowcontroller = [PlexLogin new];
    }
    [NSApp beginSheet:_plexloginwindowcontroller.window
       modalForWindow:self.view.window modalDelegate:self
       didEndSelector:@selector(plexloginDidEnd:returnCode:contextInfo:)
          contextInfo:(void *)nil];
}

- (void)plexloginDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
        [self loadplexlogin];
    }
}

- (IBAction)plexlogout:(id)sender {
    if ([PlexAuth removeplexaccount]) {
        [self loadplexlogin];
    }
}

@end
