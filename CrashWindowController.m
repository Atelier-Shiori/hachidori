//
//  CrashWindowController.m
//  Hachidori
//
//  Created by 香風智乃 on 4/6/19.
//

#import "CrashWindowController.h"

@interface CrashWindowController ()

@end

@implementation CrashWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"CrashWindowController"];
    if(!self)
        return nil;
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (IBAction)send:(id)sender {
    [NSApp stopModalWithCode:1];
    [self.window close];
}

- (IBAction)ignore:(id)sender {
    [NSApp stopModalWithCode:0];
    [self.window close];
}
- (IBAction)privacypolicy:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://malupdaterosx.moe/hachidori/privacy-policy/"]];
}

@end
