//
//  StatusUpdateWindow.m
//  Hachidori
//
//  Created by 桐間紗路 on 2017/06/12.
//  Copyright 2009-2018 Atelier Shiori and James Moy All rights reserved. Code licensed under New BSD License
//

#import "StatusUpdateWindow.h"
#import "Hachidori.h"
#import "AppDelegate.h"
#import "AniListScoreConvert.h"

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
    _showtitle.objectValue = haengine.LastScrobbledActualTitle;
    // Set rating menu based on user's rating preferences
    switch (haengine.currentService) {
        case 0: {
            _showscore.hidden = NO;
            _advancedscorefield.hidden = YES;
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
            [_showscore selectItemWithTag:haengine.TitleScore];
            break;
        }
        case 1: {
            switch (haengine.ratingtype) {
                case ratingPoint100:
                    _showscore.hidden = YES;
                    _advancedscorefield.hidden = NO;
                    _advancedscoreformatter.maximum = @(100);
                    break;
                case ratingPoint10Decimal:
                    _showscore.hidden = YES;
                    _advancedscorefield.hidden = NO;
                    _advancedscoreformatter.maximum = @(100);
                    break;
                case ratingPoint10:
                    _showscore.hidden = NO;
                    _advancedscorefield.hidden = YES;
                    _showscore.menu = _scoremenu;
                    break;
                case ratingPoint5:
                    _showscore.hidden = NO;
                    _advancedscorefield.hidden = YES;
                    _showscore.menu = _anilistfivescoremenu;
                    break;
                case ratingPoint3:
                    _showscore.hidden = NO;
                    _advancedscorefield.hidden = YES;
                    _showscore.menu = _anilistthreescoremenu;
                    break;
            }
            // Convert scores
            if (haengine.ratingtype == ratingPoint100) {
                _advancedscorefield.intValue = [AniListScoreConvert convertAniListScoreToActualScore:haengine.TitleScore withScoreType:haengine.ratingtype].intValue;
            }
            else if (haengine.ratingtype == ratingPoint10Decimal) {
                _advancedscorefield.floatValue = [AniListScoreConvert convertAniListScoreToActualScore:haengine.TitleScore withScoreType:haengine.ratingtype].floatValue;
            }
            else {
                [_showscore selectItemWithTag:[AniListScoreConvert convertAniListScoreToActualScore:haengine.TitleScore withScoreType:haengine.ratingtype].intValue];
            }
            break;
        }
    }
    _episodefield.stringValue = [NSString stringWithFormat:@"%i", haengine.DetectedCurrentEpisode];
    if (haengine.TotalEpisodes  !=0) {
        _epiformatter.maximum = @(haengine.TotalEpisodes);
    }
    [_showstatus selectItemAtIndex:[haengine getWatchStatus]];
    _notes.string = haengine.TitleNotes;
    _isPrivate.state = haengine.isPrivate;
    // Stop Timer temporarily if scrobbling is turned on
    AppDelegate *appdel = (AppDelegate *)[NSApplication sharedApplication].delegate;
    if (appdel.scrobbling) {
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
