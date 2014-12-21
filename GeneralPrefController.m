//
//  GeneralPrefController.m
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "GeneralPrefController.h"


@implementation GeneralPrefController
- (id)init
{
	return [super initWithNibName:@"GeneralPreferenceView" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController
-(void)loadView{
    [super loadView];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9){
        // Disable Yosemite UI options
        [disablenewtitlebar setEnabled:NO];
        [disablevibarency setEnabled: NO];
    }
}
- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}
-(IBAction)clearSearchCache:(id)sender{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[NSMutableArray alloc] init] forKey:@"searchcache"];
    NSLog(@"%@", [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"searchcache"]]);
}
@end
