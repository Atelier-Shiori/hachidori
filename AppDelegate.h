//
//  AppDelegate.h
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <CMCrashReporter/CMCrashReporter.h>
#import "Hachidori.h"

@class Hachidori;
@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, NSSharingServiceDelegate, NSSharingServicePickerDelegate> {
	/* Windows */
    __unsafe_unretained NSWindow *window;
	__unsafe_unretained NSWindow *historywindow;
	__unsafe_unretained NSWindow *updatepanel;
	/* General Stuff */
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSTableView *historytable;
    NSStatusItem                *statusItem;
    NSImage                        *statusImage;
    NSImage                        *statusHighlightImage;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSTimer * timer;
	IBOutlet NSMenuItem * togglescrobbler;
    IBOutlet NSMenuItem * updatenow;
	IBOutlet NSTextField * ScrobblerStatus;
	IBOutlet NSTextField * LastScrobbled;
    IBOutlet NSTextView * animeinfo;
    IBOutlet NSImageView * img;
	int choice;
	BOOL scrobbling;
    BOOL scrobbleractive;
	/* Hachidori Scrobbling/Updating Class */
	Hachidori * haengine;
	/* Update Status Sheet Window IBOutlets */
	IBOutlet NSToolbarItem * updatetoolbaritem;
    IBOutlet NSToolbarItem * sharetoolbaritem;
	IBOutlet NSTextField * showtitle;
	IBOutlet NSPopUpButton * showstatus;
    IBOutlet NSTextField * showscore;
    IBOutlet NSTextView * notes;
	NSWindowController *_preferencesWindowController;
}
@property (nonatomic, readonly) NSWindowController *preferencesWindowController;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *historywindow;
@property (assign) IBOutlet NSWindow *updatepanel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

-(void)showPreferences:(id)sender;
-(void)showhistory:(id)sender;
-(IBAction)togglescrobblewindow:(id)sender;
-(void)addrecord:(NSString *)title
		 Episode:(NSString *)episode
			Date:(NSDate *)date;
-(IBAction)clearhistory:(id)sender;
-(void)clearhistoryended:(NSAlert *)alert
					code:(int)choice
				  conext:(void *)v;
-(void)setStatusToolTip:(NSString*)toolTip;
-(IBAction)toggletimer:(id)sender;
-(void)autostarttimer;
-(void)firetimer:(NSTimer *)aTimer;
-(void)starttimer;
-(void)stoptimer;
-(void)setStatusText:(NSString*)messagetext;
-(void)setLastScrobbledTitle:(NSString*)messagetext;
-(IBAction)updatestatus:(id)sender;
-(IBAction)updatenow:(id)sender;
-(IBAction)closeupdatestatus:(id)sender;
-(IBAction)updatetitlestatus:(id)sender;
-(IBAction)showPreferences:(id)sender;
-(IBAction)getHelp:(id)sender;
- (void)appendToAnimeInfo:(NSString*)text;
-(void)showNotication:(NSString *)title message:(NSString *) message;

@end
