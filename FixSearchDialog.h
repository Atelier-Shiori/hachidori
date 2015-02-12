//
//  FixSearchDialog.h
//  Hachidori
//
//  Created by 高町なのは on 2014/11/15.
//  Copyright (c) 2014年 Atelier Shiori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FixSearchDialog : NSWindowController{
    IBOutlet NSArrayController * arraycontroller;
    IBOutlet NSTextField *search;
    IBOutlet NSButton * deleteoncorrection;
    IBOutlet NSButton * onetimecorrection;
    IBOutlet NSTableView *tb;
    NSString * selectedtitle;
    NSString * selectedaniid;
	int selectedtotalepisodes;
    NSString * searchquery;
    bool correction;
    bool allowdelete;
}
-(id)init;
-(void)setCorrection:(BOOL)correct;
-(void)setAllowDelete:(BOOL)deleteallowed;
-(NSString *)getSelectedTitle;
-(NSString *)getSelectedAniID;
-(int)getSelectedTotalEpisodes;
-(bool)getdeleteTitleonCorrection;
-(bool)getcorrectonce;
-(void)setSearchField:(NSString *)term;
@end
