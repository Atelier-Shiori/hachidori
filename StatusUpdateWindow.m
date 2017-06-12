//
//  StatusUpdateWindow.m
//  Hachidori
//
//  Created by 桐間紗路 on 2017/06/12.
//  Copyright 2009-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "StatusUpdateWindow.h"
#import "Hachidori.h"
#import "AppDelegate.h"

@interface StatusUpdateWindow ()

@end

@implementation StatusUpdateWindow

- (instancetype)init{
    self = [super initWithWindowNibName:@"StatusUpdateWindow"];
    if(!self)
        return nil;
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)showUpdateDialog:(NSWindow *) w withHachidori:(Hachidori *)haengine{
    // Show Sheet
    [NSApp beginSheet:self.window
       modalForWindow:w modalDelegate:self
       didEndSelector:@selector(updateDidEnd:returnCode:contextInfo:)
          contextInfo:(void *)nil];
    // Set up UI
    _showtitle.objectValue = [haengine getLastScrobbledActualTitle];
    // Set rating menu based on user's rating preferences
    switch (haengine.ratingtype){
        case ratingSimple:
            _showscore.menu = _simpleratingmenu;
            break;
        case ratingStandard:
            _showscore.menu = _standardratingmenu;
            break;
        case ratingAdvanced:
            _showscore.menu = _advancedratingmenu;
            break;
        default:
            _showscore.menu = _simpleratingmenu;
            break;
    }
    [_showscore selectItemWithTag:[haengine getTitleScore]];
    _episodefield.stringValue = [NSString stringWithFormat:@"%i", [haengine getCurrentEpisode]];
    if ([haengine getTotalEpisodes]  !=0) {
        _epiformatter.maximum = @([haengine getTotalEpisodes]);
    }
    [_showstatus selectItemAtIndex:[haengine getWatchStatus]];
    _notes.string = [haengine getNotes];
    _isPrivate.state = [haengine getPrivate];
    // Stop Timer temporarily if scrobbling is turned on
    AppDelegate *appdel = (AppDelegate *)[NSApplication sharedApplication].delegate;
    if ([appdel getisScrobbling]) {
        [appdel stoptimer];
    }
    
}

- (IBAction)closeupdatestatus:(id)sender {
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:0];
}

- (IBAction)updatetitlestatus:(id)sender {
    [self.window orderOut:self];
    [NSApp endSheet:self.window returnCode:1];
}

- (void)updateDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    self.completion(returnCode);
}
@end
