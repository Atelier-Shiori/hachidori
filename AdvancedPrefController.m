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

- (id)init
{
    return [super initWithNibName:@"AdvancedPrefController" bundle:nil];
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
@end
