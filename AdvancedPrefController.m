//
//  AdvancedPrefController.m
//  Hachidori
//
//  Created by Tail Red on 3/21/15.
//
//

#import "AdvancedPrefController.h"

@interface AdvancedPrefController ()

@end

@implementation AdvancedPrefController

- (instancetype)init {
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
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://help.malupdaterosx.moe/hachidori/advanced-options/"]];
}
    
- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField * textfield = notification.object;
    if ([textfield.identifier isEqualToString:@"kodiaddress"]) {
        [NSNotificationCenter.defaultCenter postNotificationName:@"KodiAddressChanged" object:textfield.stringValue];
    }
    
}
- (IBAction)setKodiReach:(id)sender {
    [NSNotificationCenter.defaultCenter postNotificationName:@"KodiToggled" object:nil];
}

@end
