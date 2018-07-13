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

@synthesize appdelegate;
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
