//
//  FixSearchDialog.h
//  Hachidori
//
//  Created by 高町なのは on 2014/11/15.
//  Copyright (c) 2014年 MAL Updater OS X Group and James Moy All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FixSearchDialog : NSWindowController
@property (strong) IBOutlet NSArrayController *arraycontroller;
@property (strong) IBOutlet NSTextField *search;
@property (strong) IBOutlet NSButton *deleteoncorrection;
@property (strong) IBOutlet NSButton *onetimecorrection;
@property (strong) IBOutlet NSTableView *tb;
@property (strong, getter=getSelectedTitle) NSString *selectedtitle;
@property (strong, getter=getSelectedAniID) NSNumber *selectedaniid;
@property (getter=getSelectedTotalEpisodes) int selectedtotalepisodes;
@property (strong, setter=setSearchField:) NSString *searchquery;
@property (setter=setCorrection:) bool correction;
@property (setter=setAllowDelete:) bool allowdelete;

- (instancetype)init;
- (bool)getdeleteTitleonCorrection;
- (bool)getcorrectonce;
@end
