//
//  GeneralPrefController.h
//  Hachidori
//
//  Created by Nanoha Takamachi on 2014/10/18.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"
#import "MASShortcutView.h"



@interface GeneralPrefController : NSViewController <MASPreferencesViewController> {
    IBOutlet NSButton * disablenewtitlebar;
    IBOutlet NSButton * disablevibarency;
}
@property (nonatomic, weak) IBOutlet MASShortcutView *scrobblenowshortcutView;
@property (nonatomic, weak) IBOutlet MASShortcutView *statusshortcutView;
@end
