//
//  TorrentBrowserController.h
//  TorrentBrowser
//
//  Created by James Moy on 2017/11/05.
//  Copyright © 2017 Moy IT Solutions. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TorrentManager;
@class ruleseditor;

@interface TorrentBrowserController : NSWindowController
@property (strong) TorrentManager *tmanager;
@property (strong) IBOutlet NSTableView *tableview;
@property (strong) IBOutlet NSPopUpButton *popupbtn;
@property (strong) IBOutlet NSSearchField *searchfield;
@property (strong) ruleseditor *ruleseditor;

@property (strong) IBOutlet NSArrayController *supportedsites;
@property (strong) IBOutlet NSArrayController *searchresults;

- (id)initwithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (NSViewController *)getBittorrentPreferences;
- (IBAction)addDownloadRule:(id)sender;
- (IBAction)manageDownloadRules:(id)sender;
- (IBAction)refresh:(id)sender;
- (IBAction)downloaditem:(id)sender;
- (IBAction)changesource:(id)sender;
- (IBAction)performSearch:(id)sender;
@end
