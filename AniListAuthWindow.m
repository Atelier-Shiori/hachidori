//
//  AniListAuthWindow.m
//  Shukofukurou
//
//  Created by 小鳥遊六花 on 4/3/18.
//  Copyright © 2017-2018 MAL Updater OS X Group and Moy IT Solutions. All rights reserved. Licensed under 3-clause BSD License
//

#import "AniListAuthWindow.h"
#import "AuthWebView.h"

@interface AniListAuthWindow ()
@property (strong) AuthWebView *awebview;
@property (strong) IBOutlet NSView *containerview;
@end

@implementation AniListAuthWindow

- (instancetype)init {
    self = [super initWithWindowNibName:@"AniListAuthWindow"];
    if (!self) {
        return nil;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    if (!_awebview) {
        _awebview = [AuthWebView new];
    }
    __weak AniListAuthWindow *weakself = self;
    _awebview.completion = ^(NSString *pin) {
        weakself.pin = pin;
        [weakself.window.sheetParent endSheet:weakself.window returnCode:NSModalResponseOK];
    };
    _awebview.view.frame = _containerview.frame;
    [_awebview.view setFrameOrigin:NSMakePoint(0, 0)];
    [_containerview  addSubview:_awebview.view];
}


- (IBAction)cancel:(id)sender {
    [_awebview resetWebView];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (void)loadAuthorizationForService:(int)service {
    [_awebview loadAuthorization:service];
}

@end
