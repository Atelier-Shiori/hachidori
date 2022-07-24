//
//  SoftwareUpdatesPref.m
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "SoftwareUpdatesPref.h"


@implementation SoftwareUpdatesPref
- (instancetype)init
{
    return [super initWithNibName:@"SoftwareUpdateView" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"SoftwareUpdatesPreferences";
}

- (NSImage *)toolbarItemImage
{
    if (@available(macOS 11.0, *)) {
        return [NSImage imageWithSystemSymbolName:@"arrow.triangle.2.circlepath" accessibilityDescription:nil];
    } else {
        // Fallback on earlier versions
        return [NSImage imageNamed:@"SoftwareUpdates"];
    }
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Software Updates", @"Toolbar item name for the Software Updatespreference pane");
}

- (void)loadView{
    [super loadView];
    if([(NSString *)[[NSUserDefaults standardUserDefaults] valueForKey:@"SUFeedURL"] isEqualToString:@"https://updates.malupdaterosx.moe/hachidori-beta/profileInfo.php"]) {
        _betacheck.state = 1;
    }
}
- (IBAction)setBetaChannel:(id)sender{
    if (_betacheck.state == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:@"https://updates.malupdaterosx.moe/hachidori-beta/profileInfo.php" forKey:@"SUFeedURL"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setObject:@"https://updates.malupdaterosx.moe/hachidori/profileInfo.php" forKey:@"SUFeedURL"];
    }
}
@end
