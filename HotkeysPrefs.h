//
//  HotkeysPrefs.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/12/21.
//
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"
#import "MASShortcutView.h"

@interface HotkeysPrefs : NSViewController <MASPreferencesViewController>{
    
}
@property (nonatomic, weak) IBOutlet MASShortcutView *confirmupdateshortcutView;
@property (nonatomic, weak) IBOutlet MASShortcutView *scrobblenowshortcutView;
@property (nonatomic, weak) IBOutlet MASShortcutView *statusshortcutView;
@property (nonatomic, weak) IBOutlet MASShortcutView *toggleautoscrobbleshortcutView;

@end
