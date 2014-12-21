//
//  HotkeysPrefs.m
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/12/21.
//
//

#import "HotkeysPrefs.h"
#import "HotKeyConstants.h"
#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"

@interface HotkeysPrefs ()

@end

@implementation HotkeysPrefs
- (id)init
{
    return [super initWithNibName:@"HotkeysPrefs" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController
-(void)loadView{
    [super loadView];
    // Set Shortcut Recorder Viewer Defaults Key
    self.confirmupdateshortcutView.associatedUserDefaultsKey = kPreferenceConfirmUpdateShortcut;
    self.scrobblenowshortcutView.associatedUserDefaultsKey = kPreferenceScrobbleNowShortcut;
    self.statusshortcutView.associatedUserDefaultsKey = kPreferenceShowStatusMenuShortcut;
    self.toggleautoscrobbleshortcutView.associatedUserDefaultsKey = kPreferenceToggleScrobblingShortcut;
}
- (NSString *)identifier
{
    return @"HotkeyPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"hotkey.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Hotkeys", @"Toolbar item name for the Hotkeys preference pane");
}


@end
