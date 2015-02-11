//
//  SoftwareUpdatesPref.m
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
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
    return [NSImage imageNamed:@"SoftwareUpdates"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Software Updates", @"Toolbar item name for the Software Updatespreference pane");
}
@end
