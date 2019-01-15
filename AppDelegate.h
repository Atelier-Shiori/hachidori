//
//  AppDelegate.h
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2018 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <AFNetworking/AFOAuth2Manager.h>

@class Hachidori;
@class FixSearchDialog;
@class HistoryWindow;
@class DonationWindowController;
@class MSWeakTimer;
@class OfflineViewQueue;
@class streamlinkopen;
@class StatusUpdateWindow;
@class ShareMenu;
@class PFAboutWindowController;
@class servicemenucontroller;
#ifdef oss
#else
@class TorrentBrowserController;
@class PatreonController;
#endif

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, NSSharingServiceDelegate> {
    NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
}
@property (strong, nonatomic) dispatch_queue_t privateQueue;
@property (nonatomic, readonly) NSWindowController *preferencesWindowController;
@property (strong) IBOutlet NSWindow *window;
@property (strong) OfflineViewQueue * owindow;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly, getter=getObjectContext) NSManagedObjectContext *managedObjectContext;
@property (strong) FixSearchDialog *fsdialog;
@property (strong) HistoryWindow *historywindowcontroller;
@property (strong) DonationWindowController * dwindow;
@property (strong) IBOutlet NSView *nowplayingview;
@property (strong) IBOutlet NSView *nothingplayingview;
@property (strong) StatusUpdateWindow *updatewindow;
@property (strong) IBOutlet ShareMenu *shareMenu;
@property (strong) IBOutlet servicemenucontroller *servicemenu;
/* General Stuff */
@property (strong) IBOutlet NSMenu *statusMenu;
@property (strong) NSStatusItem *statusItem;
@property (strong) NSImage *statusImage;
@property (strong) MSWeakTimer * timer;
@property (strong) IBOutlet NSMenuItem *openstream;
@property (strong) IBOutlet NSMenuItem * togglescrobbler;
@property (strong) IBOutlet NSMenuItem * updatenow;
@property (strong) IBOutlet NSMenuItem * confirmupdate;
@property (strong) IBOutlet NSMenuItem * findtitle;
/* Updated Title Display and Operations */
@property (strong) IBOutlet NSMenuItem * seperator;
@property (strong) IBOutlet NSMenuItem * lastupdateheader;
@property (strong) IBOutlet NSMenuItem * updatecorrectmenu;
@property (strong) IBOutlet NSMenu * updatecorrect;
@property (strong) IBOutlet NSMenuItem * updatedtitle;
@property (strong) IBOutlet NSMenuItem * updatedepisode;
@property (strong) IBOutlet NSMenuItem * seperator2;
@property (strong) IBOutlet NSMenuItem * updatedcorrecttitle;
@property (strong) IBOutlet NSMenuItem * updatedupdatestatus;
@property (strong) IBOutlet NSMenuItem * revertrewatch;
@property (strong) IBOutlet NSMenuItem *shareMenuItem;
/* Status Window */
@property (strong) IBOutlet NSTextField * ScrobblerStatus;
@property (strong) IBOutlet NSTextField * LastScrobbled;
@property (strong) IBOutlet NSToolbarItem * openAnimePage;
@property (strong) IBOutlet NSTextView * animeinfo;
@property (strong) IBOutlet NSImageView * img;
@property (strong) IBOutlet NSVisualEffectView * windowcontent;
@property (strong) IBOutlet NSScrollView *animeinfooutside;
@property (getter=getisScrobbling) bool scrobbling;
@property (getter=getisScrobblingActive) bool scrobbleractive;
@property bool panelactive;
/* Hachidori Scrobbling/Updating Class */
@property (strong, getter=getHachidoriInstance) Hachidori * haengine;
/* Update Status Sheet Window IBOutlets */
@property (strong)IBOutlet NSToolbarItem * updatetoolbaritem;
@property (strong) IBOutlet NSToolbarItem * correcttoolbaritem;
@property (strong) IBOutlet NSToolbarItem * sharetoolbaritem;
@property (strong) NSWindowController *_preferencesWindowController;
@property (strong) streamlinkopen * streamlinkopenw;
@property (strong) PFAboutWindowController *aboutWindowController;
@property (weak) IBOutlet NSMenuItem *servicenamemenu;
#ifdef oss
#else
@property (strong) TorrentBrowserController *tbc;
@property (strong) PatreonController *pc;
#endif

- (void)showhistory:(id)sender;
- (IBAction)togglescrobblewindow:(id)sender;
- (void)setStatusToolTip:(NSString*)toolTip;
- (IBAction)toggletimer:(id)sender;
- (void)autostarttimer;
- (void)firetimer;
- (void)starttimer;
- (void)stoptimer;
- (void)setStatusText:(NSString*)messagetext;
- (void)setLastScrobbledTitle:(NSString*)messagetext;
- (void)setStatusMenuTitleEpisode:(NSString *)title episode:(NSString *) episode;
- (IBAction)updatestatus:(id)sender;
- (IBAction)updatestatusmenu:(id)sender;
- (void)showUpdateDialog:(NSWindow *) w;
- (IBAction)updatenow:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)getHelp:(id)sender;
- (void)appendToAnimeInfo:(NSString*)text;
- (void)showNotification:(NSString *)title message:(NSString *) message withIdentifier:(NSString *)identifier;
- (IBAction)showAboutWindow:(id)sender;
- (void)enterDonationKey;
- (NSDictionary *)getNowPlaying;
- (void)resetUI;
@end
