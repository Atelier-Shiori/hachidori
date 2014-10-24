//
//  SoftwareUpdatesPref.m
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved.
//

#import "SoftwareUpdatesPref.h"


@implementation SoftwareUpdatesPref
- (id)init
{
	return [super initWithNibName:@"SoftwareUpdateView" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"SoftwareUpdatesPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"PreferencesSoftwareUpdateIcon.tiff"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Software Updates", @"Toolbar item name for the Software Updatespreference pane");
}
-(IBAction)checkupdates:(id)sender
{
	//Initalize Update
	[[SUUpdater sharedUpdater] checkForUpdates:sender];
}
@end
