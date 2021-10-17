//
//  SyncPrefs.m
//  Hachidori
//
//  Created by 香風智乃 on 1/14/19.
//

#import "SyncPrefs.h"

@interface SyncPrefs ()

@end

@implementation SyncPrefs
- (instancetype)init {
    return [super initWithNibName:@"SyncPrefs" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"SyncPrefs";
}

- (NSImage *)toolbarItemImage
{
    if (@available(macOS 11.0, *)) {
        return [NSImage imageWithSystemSymbolName:@"arrow.left.arrow.right.circle" accessibilityDescription:nil];
    } else {
        // Fallback on earlier versions
        return [NSImage imageNamed:@"sync"];
    }
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"MultiScrobble", @"Toolbar item name for the Software MultiScrobble pane");
}

@end
