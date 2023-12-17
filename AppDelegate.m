//
//  AppDelegate.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2018 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "AppDelegate.h"
#import "Hachidori.h"
#import "Hachidori+Update.h"
#import "Hachidori+userinfo.h"
#import "Hachidori+MultiScrobble.h"
#import "OfflineViewQueue.h"
#import "PFMoveApplication.h"
#import "Preferences.h"
#import "FixSearchDialog.h"
#import "Hotkeys.h"
#import "AutoExceptions.h"
#import "AnimeRelations.h"
#import "ExceptionsCache.h"
#import "Utility.h"
#import "HistoryWindow.h"
#import "DonationWindowController.h"
#import <MSWeakTimer_macOS/MSWeakTimer.h>
#import "ClientConstants.h"
#import "StatusUpdateWindow.h"
#import <TorrentBrowser/TorrentBrowser.h>
#import "ShareMenu.h"
#import "PFAboutWindowController.h"
#import "servicemenucontroller.h"
#import "AniListScoreConvert.h"
#import "PatreonLicenseManager.h"
#import "CrashWindowController.h"

@interface AppDelegate ()
@property (strong) CrashWindowController *cwincontroller;
@end

@implementation AppDelegate

@synthesize window;
@synthesize historywindowcontroller;
@synthesize fsdialog;
@synthesize managedObjectContext;
@synthesize statusMenu;
@synthesize statusItem;
@synthesize statusImage;
@synthesize timer;
@synthesize openstream;
@synthesize togglescrobbler;
@synthesize updatenow;
@synthesize confirmupdate;
@synthesize findtitle;
@synthesize seperator;
@synthesize lastupdateheader;
@synthesize updatecorrectmenu;
@synthesize updatecorrect;
@synthesize updatedtitle;
@synthesize updatedepisode;
@synthesize seperator2;
@synthesize updatedcorrecttitle;
@synthesize updatedupdatestatus;
@synthesize revertrewatch;
@synthesize shareMenuItem;
@synthesize ScrobblerStatus;
@synthesize LastScrobbled;
@synthesize openAnimePage;
@synthesize animeinfo;
@synthesize img;
@synthesize windowcontent;
@synthesize animeinfooutside;
@synthesize scrobbling;
@synthesize scrobbleractive;
@synthesize panelactive;
@synthesize haengine;
@synthesize updatetoolbaritem;
@synthesize correcttoolbaritem;
@synthesize sharetoolbaritem;
@synthesize _preferencesWindowController;
@synthesize streamlinkopenw;


#pragma mark -
#pragma mark Initalization
/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "Hachidori" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = (paths.count > 0) ? paths[0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Hachidori"];
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
	
    NSManagedObjectModel *mom = self.managedObjectModel;
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"Update History.sqlite"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES
                              };
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:url
                                                        options:options
                                                          error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        persistentStoreCoordinator = nil;
        return nil;
    }    
    
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext) return managedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = coordinator;
	
    return managedObjectContext;
}
+ (void)initialize {
	//Create a Dictionary
	NSMutableDictionary * defaultValues = [NSMutableDictionary dictionary];
	
	// Defaults
	defaultValues[@"Token"] = @"";
	defaultValues[@"ScrobbleatStartup"] = @NO;
    defaultValues[@"setprivate"] = @NO;
    defaultValues[@"useSearchCache"] = @YES;
    defaultValues[@"exceptions"] = [[NSMutableArray alloc] init];
    defaultValues[@"ignoredirectories"] = [[NSMutableArray alloc] init];
    defaultValues[@"IgnoreTitleRules"] = [[NSMutableArray alloc] init];
    defaultValues[@"ConfirmNewTitle"] = @YES;
    defaultValues[@"ConfirmUpdates"] = @NO;
	defaultValues[@"UseAutoExceptions"] = @YES;
    defaultValues[@"UseAnimeRelations"] = @YES;
    defaultValues[@"enablekodiapi"] = @NO;
    defaultValues[@"RewatchEnabled"] = @YES;
    defaultValues[@"kodiaddress"] = @"";
    defaultValues[@"kodiport"] = @"3005";
#ifdef oss
    defaultValues[@"donated"] = @YES;
    defaultValues[@"oss"] = @YES;
#else
    defaultValues[@"donated"] = @NO;
    defaultValues[@"activepatron"] = @NO;
    defaultValues[@"oss"] = @NO;
    defaultValues[@"autodownloadtorrents"] = @NO;
    defaultValues[@"autodownloadinterval"] = @(3600);
#endif
    defaultValues[@"MALAPIURL"] = @"https://malapi.malupdaterosx.moe";
    defaultValues[@"timerinterval"] = @(300);
    defaultValues[@"showcorrection"] = @YES;
    defaultValues[@"NSApplicationCrashOnExceptions"] = @YES;
    defaultValues[@"enableplexapi"] = @NO;
    defaultValues[@"plexaddress"] = @"localhost";
    defaultValues[@"plexport"] = @"32400";
    defaultValues[@"plexidentifier"] = @"Hachidori_Plex_Client";
    defaultValues[@"plexusehttps"] = @NO;
    defaultValues[@"currentservice"] = @(0);
    defaultValues[@"torrentagreement"] = @NO;
    defaultValues[@"torrentsiteselected"] = @(0);
    defaultValues[@"useDirectoryAsWhitelist"] = @NO;
    defaultValues[@"youtubedetection"] = @NO;
    // Social
    defaultValues[@"tweetonscrobble"] = @NO;
    defaultValues[@"twitteraddanime"] = @YES;
    defaultValues[@"twitterupdateanime"] = @YES;
    defaultValues[@"twitterupdatestatus"] = @NO;
    defaultValues[@"twitteraddanimeformat"] = @"Started watching %title% Episode %episode% on %service% - %url% #hachidori";
    defaultValues[@"twitterupdateanimeformat"] = @"%status% %title% Episode %episode% on %service% - %url% #hachidori";
    defaultValues[@"twitterupdatestatusformat"] =  @"Updated %title% Episode %episode% (%status%) on %service% - %url% #hachidori";
    defaultValues[@"usediscordrichpresence"] = @NO;
    // MultiScrobble
    defaultValues[@"multiscrobbleenabled"] = @NO;
    defaultValues[@"multiscrobblescrobblesenabled"] = @YES;
    defaultValues[@"multiscrobbleentryupdatesenabled"] = @YES;
    defaultValues[@"multiscrobblescorrectionsenabled"] = @NO;
    defaultValues[@"multiscrobbleanilistenabled"] = @NO;
    defaultValues[@"multiscrobblekitsuenabled"] = @NO;
    defaultValues[@"sendanalytics"] = @YES;
    // Refresh Token Fail State
    defaultValues[@"AniListRefreshFailed"] = @NO;
    defaultValues[@"KitsuRefreshFailed"] = @NO;
    defaultValues[@"MALRefreshFailed"] = @NO;
    
	//Register Dictionary
	[[NSUserDefaults standardUserDefaults]
	 registerDefaults:defaultValues];
}
- (void) awakeFromNib {
    // Register queue
    _privateQueue = dispatch_queue_create("moe.ateliershiori.Hachidori", DISPATCH_QUEUE_CONCURRENT);
    
    //Create the NSStatusBar and set its length
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    statusImage = [NSImage imageNamed:@"hachidori-status"];
    
    //Yosemite Dark Menu Support
    [statusImage setTemplate:YES];
    
    //Sets the images in our NSStatusItem
    statusItem.image = statusImage;
    
    //Tells the NSStatusItem what menu to load
    statusItem.menu = statusMenu;
    
    //Sets the tooptip for our item
    [statusItem setToolTip:NSLocalizedString(@"Hachidori",nil)];
    
    //Enables highlighting
    [statusItem setHighlightMode:YES];
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
#ifdef oss
#else
    [MSACAppCenter start:@"d37cc407-6d11-42e6-84e7-222899deb28c" withServices:@[
                                                                              [MSACAnalytics class],
                                                                              [MSACCrashes class]
                                                                              ]];
    [MSACCrashes setDelegate:self];
    [MSACCrashes setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
    [MSACAnalytics setEnabled:[NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]];
#endif
	// Initialize haengine
    haengine = [[Hachidori alloc] init];
	haengine.managedObjectContext = managedObjectContext;
    
    // Add Observers
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recievedNotification:) name:@"MultiScrobbleNotification" object:nil];
#ifdef oss
#else
    // Set up Torrent Browser (closed source)
    _tbc = [[TorrentBrowserController alloc] initwithManagedObjectContext:managedObjectContext];
    // Start Timer for Auto Downloading of Torrents if enabled
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"autodownloadtorrents"]) {
        if ([_tbc.tmanager startAutoDownloadTimer]) {
            NSLog(@"Timer started");
        }
        else {
            NSLog(@"Failed to start timer.");
        }
    }
    
    // Check Beta
    if ([Utility checkBeta]) {
        [self showNotification:@"Experimental Update Branch is Enabled" message:@"Hachidori will use the prerelease branch since you are using a prerelease version." withIdentifier:[NSString stringWithFormat:@"betanotif-%@", [NSDate date]]];
    }
#endif
    
    #ifdef DEBUG
    #else
        // Check if Application is in the /Applications Folder
        PFMoveToApplicationsFolderIfNecessary();
    #endif
    
    // Show Donation Message
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"donated"] && [NSUserDefaults.standardUserDefaults boolForKey:@"patreon_license"]) {
        [Utility patreonDonateCheck:self];
    }
    else {
        [Utility donateCheck:self];
    }
    // Set Defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //Set Notification Center Delegate
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    //Register Global Hotkey
    [self registerHotkey];
    
	// Disable Update and Share Buttons
	[updatetoolbaritem setEnabled:NO];
    [sharetoolbaritem setEnabled:NO];
    [correcttoolbaritem setEnabled:NO];
    [openAnimePage setEnabled:NO];
	// Hide Window
	[window close];
	
    //Set up Yosemite UI Enhancements
    if ([defaults boolForKey:@"DisableYosemiteTitleBar"] != 1) {
        // OS X 10.10 code here.
        //Hide Title Bar
        if (@available(macOS 11, *)) {
            self.window.titleVisibility = NSWindowTitleVisible;
            self.window.toolbarStyle = NSWindowToolbarStyleUnified;
        }
        else {
            self.window.titleVisibility = NSWindowTitleHidden;
        }
        // Fix Window Size
        NSRect frame = window.frame;
        frame.size = CGSizeMake(460, 291);
        [window setFrame:frame display:YES];
    }
    else {
        if (@available(macOS 11, *)) {
            self.window.toolbarStyle = NSWindowToolbarStyleExpanded;
            // Fix Window Size
            NSRect frame = window.frame;
            frame.size = CGSizeMake(460, 291);
            [window setFrame:frame display:YES];
        }
    }
    if ([defaults boolForKey:@"DisableYosemiteVibrance"] != 1) {
        //Add NSVisualEffectView to Window
        windowcontent.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        windowcontent.state = NSVisualEffectStateFollowsWindowActiveState;
        //Make Animeinfo textview transparrent
        [animeinfooutside setDrawsBackground:NO];
        animeinfo.backgroundColor = [NSColor clearColor];
    }
    else {
        windowcontent.state = NSVisualEffectStateInactive;
        [animeinfooutside setDrawsBackground:NO];
        animeinfo.backgroundColor = [NSColor clearColor];
    }

    // Fix template images
    // There is a bug where template images are not made even if they are set in XCAssets
    NSArray *images = @[@"update", @"history", @"correct", @"Info", @"clear"];
    NSImage * image;
    for (NSString *imagename in images) {
            image = [NSImage imageNamed:imagename];
            [image setTemplate:YES];
    }
    // Set up Service Menu
    [_servicemenu setmenuitemvaluefromdefaults];
    __weak AppDelegate *weakself = self;
    _servicemenu.actionblock = ^(int selected, int previousservice) {
        [weakself.haengine setNotifier];
        [weakself showNotification:@"Changed Services" message:[NSString stringWithFormat:@"Now using %@", [Hachidori currentServiceName]] withIdentifier:@"servicechanged"];
        if (!weakself.haengine.lastscrobble) {
            [weakself resetUI];
        }
        else {
            [weakself performRefreshUI:1];
            dispatch_async(weakself.privateQueue, ^{
                weakself.haengine.ratingtype = [weakself.haengine getRatingType];
            });
        }
        //[weakself.haengine resetinfo];
        //
        weakself.servicenamemenu.enabled = NO;
    };
    [haengine checkaccountinformation];
	// Notify User if there is no Account Info
	if (![Hachidori getCurrentFirstAccount]) {
        // First time prompt
        NSAlert * alert = [[NSAlert alloc] init] ;
        [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
        [alert setMessageText:NSLocalizedString(@"Welcome to Hachidori",nil)];
        [alert setInformativeText:NSLocalizedString(@"Before using this program, you need to add an account. Do you want to open Preferences to authorize your account now?",nil)];
        // Set Message type to Warning
        alert.alertStyle = NSInformationalAlertStyle;
        if ([alert runModal]== NSAlertFirstButtonReturn) {
            // Show Preference Window and go to Login Preference Pane
            [NSApp activateIgnoringOtherApps:YES];
            [self.preferencesWindowController showWindow:nil];
            [(MASPreferencesWindowController *)self.preferencesWindowController selectControllerAtIndex:1];
        }
	}
	// Autostart Scrobble at Startup
	if ([defaults boolForKey:@"ScrobbleatStartup"] == 1) {
		[self autostarttimer];
	}
    // Import existing Exceptions Data
    [AutoExceptions importToCoreData];
    
    // Temporarily disable MAL Sync
    [defaults setBool:FALSE forKey:@"MALSyncEnabled"];
    _servicenamemenu.enabled = NO;
    
    [MSACAnalytics trackEvent:@"App Loaded" withProperties:@{@"donated" : [NSUserDefaults.standardUserDefaults boolForKey:@"donated"] ? @"YES" : @"NO"}];
    
    // Auth URL handling
    [[NSAppleEventManager sharedAppleEventManager]
     setEventHandler:self
     andSelector:@selector(handleURLEvent:withReplyEvent:)
     forEventClass:kInternetEventClass
     andEventID:kAEGetURL];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}


- (void)recievedNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"MultiScrobbleNotification"]) {
        if ([notification.object isKindOfClass:[NSDictionary class]]) {
            NSDictionary *notificationinfo = notification.object;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showNotification:notificationinfo[@"title"] message:notificationinfo[@"message"] withIdentifier:notificationinfo[@"identifier"]];
            });
        }
    }
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event
    withReplyEvent:(NSAppleEventDescriptor*)replyEvent {
    NSString* url = [event paramDescriptorForKeyword:keyDirectObject].stringValue;
    [NSNotificationCenter.defaultCenter postNotificationName:@"hachidori_auth" object:url];
}

#pragma mark General UI Functions
- (NSWindowController *)preferencesWindowController {
    if (!_preferencesWindowController)
    {
        NSViewController *generalViewController = [[GeneralPrefController alloc] init];
        NSViewController *loginViewController = [[LoginPref alloc] initwithAppDelegate:self];
        NSViewController *syncController = [SyncPrefs new];
		NSViewController *suViewController = [[SoftwareUpdatesPref alloc] init];
        NSViewController *exceptionsViewController = [[ExceptionsPref alloc] init];
        NSViewController *hotkeyViewController = [[HotkeysPrefs alloc] init];
        NSViewController *plexviewController = [PlexPrefs new];
        NSViewController *advancedViewController = [[AdvancedPrefController alloc] init];
        NSViewController *socialViewController = [[SocialPrefController alloc] init];
        NSArray *controllers;
#ifdef oss
        controllers = @[generalViewController, loginViewController, socialViewController, syncController, hotkeyViewController , plexviewController, exceptionsViewController, suViewController, advancedViewController];
#else
        NSViewController *bittorrentpreferences = [[BittorrentPreferences alloc] initwithTorrentManager:_tbc.tmanager];
        controllers = @[generalViewController, loginViewController, socialViewController, syncController, hotkeyViewController , plexviewController, bittorrentpreferences, exceptionsViewController, suViewController, advancedViewController];
#endif
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers];
    }
    return _preferencesWindowController;
}

- (IBAction)showPreferences:(id)sender
{
	//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
	[NSApp activateIgnoringOtherApps:YES];
	[self.preferencesWindowController showWindow:nil];
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
    if (!managedObjectContext) return NSTerminateNow;
	
    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
	
    if (!managedObjectContext.hasChanges) return NSTerminateNow;
	
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
		
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.
		
        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
		
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
		
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = question;
        alert.informativeText = info;
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
		
        NSInteger answer = [alert runModal];

        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
	
    return NSTerminateNow;
}
- (IBAction)togglescrobblewindow:(id)sender
{
	if (window.visible) {
        [window close];
	} else { 
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
		[window makeKeyAndOrderFront:self]; 
	} 
}
- (IBAction)showOfflineQueue:(id)sender{
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    if (!_owindow) {
        _owindow = [[OfflineViewQueue alloc] init];
    }
    [_owindow.window makeKeyAndOrderFront:nil];
}
- (IBAction)getHelp:(id)sender{
    //Show Help
 	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://help.malupdaterosx.moe/hachidori/"]];
}

- (IBAction)reportIssue:(id)sender{
    //Show Help
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.malupdaterosx.moe/index.php?forums/hachidori-issue-tracker-support.10/"]];
}

- (IBAction)reportStreamIssue:(id)sender{
    //Show Help
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.malupdaterosx.moe/index.php?forums/hachidori-stream-detection-support.11/"]];
}

- (IBAction)showAboutWindow:(id)sender{
    // Properly show the about window in a menu item application
    [NSApp activateIgnoringOtherApps:YES];
    if (!_aboutWindowController) {
        _aboutWindowController = [PFAboutWindowController new];
    }
    (self.aboutWindowController).appURL = [[NSURL alloc] initWithString:@"https://malupdaterosx.moe/hachidori/"];
    NSMutableString *copyrightstr = [NSMutableString new];
    NSDictionary *bundleDict = [NSBundle mainBundle].infoDictionary;
    [copyrightstr appendFormat:@"%@ \r\r",bundleDict[@"NSHumanReadableCopyright"]];
    if (((NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"donated"]).boolValue) {
        [copyrightstr appendFormat:@"This copy is registered to: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"donor"]];
    }
    else {
        [copyrightstr appendString:@"UNREGISTERED COPY"];
    }
    (self.aboutWindowController).appCopyright = [[NSAttributedString alloc] initWithString:copyrightstr
                                                                                attributes:@{
                                                                                             NSForegroundColorAttributeName:[NSColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f],
                                                                                             NSFontAttributeName:[NSFont fontWithName:[NSFont systemFontOfSize:12.0f].familyName size:11]}];
    
    [self.aboutWindowController showWindow:nil];
}
- (void)disableUpdateItems{
    // Disables update options to prevent erorrs
    panelactive = true;
    [statusMenu setAutoenablesItems:NO];
    [updatecorrect setAutoenablesItems:NO];
    [updatenow setEnabled:NO];
    [togglescrobbler setEnabled:NO];
    [updatedcorrecttitle setEnabled:NO];
    [updatedupdatestatus setEnabled:NO];
    [revertrewatch setEnabled:NO];
    [confirmupdate setEnabled:NO];
	[findtitle setEnabled:NO];
    [openstream setEnabled:NO];
    [_servicemenu enableservicemenuitems:NO];
    _servicenamemenu.enabled = NO;
}
- (void)enableUpdateItems{
    // Reenables update options
    panelactive = false;
    [updatenow setEnabled:YES];
    [togglescrobbler setEnabled:YES];
    [updatedcorrecttitle setEnabled:YES];
    if (confirmupdate.hidden) {
        [updatedupdatestatus setEnabled:YES];
    }
    if (!confirmupdate.hidden && !haengine.lastscrobble.LastScrobbledTitleNew) {
        [updatedupdatestatus setEnabled:YES];
        [updatecorrect setAutoenablesItems:YES];
        [revertrewatch setEnabled:YES];
    }
    [updatecorrect setAutoenablesItems:YES];
    [confirmupdate setEnabled:YES];
    [findtitle setEnabled:YES];
    [openstream setEnabled:YES];
    [_servicemenu enableservicemenuitems:YES];
    _servicenamemenu.enabled = NO;
}
- (void)unhideMenus{
    //Show Last Scrobbled Title and operations */
    [seperator setHidden:NO];
    [lastupdateheader setHidden:NO];
    [updatedtitle setHidden:NO];
    [updatedepisode setHidden:NO];
    [seperator2 setHidden:NO];
    [updatecorrectmenu setHidden:NO];
    [updatedcorrecttitle setHidden:NO];
    [shareMenuItem setHidden:NO];
}
- (void)toggleScrobblingUIEnable:(BOOL)enable{
    dispatch_async(dispatch_get_main_queue(), ^{
        updatenow.enabled = enable;
        togglescrobbler.enabled = enable;
        confirmupdate.enabled = enable;
        findtitle.enabled = enable;
        revertrewatch.enabled = enable;
        openstream.enabled = enable;
        _servicenamemenu.enabled = NO;
        [_servicemenu enableservicemenuitems:enable];
        if (!enable) {
            [updatenow setTitle:NSLocalizedString(@"Updating...",nil)];
            [self setStatusText:NSLocalizedString(@"Scrobble Status: Scrobbling...",nil)];
        }
        else {
            [updatenow setTitle:NSLocalizedString(@"Update Now",nil)];
        }
        _servicenamemenu.enabled = NO;
    });
}
- (void)EnableStatusUpdating:(BOOL)enable{
	updatecorrect.autoenablesItems = enable;
    updatetoolbaritem.enabled = enable;
    updatedupdatestatus.enabled = enable;
    revertrewatch.enabled = enable;
    _servicenamemenu.enabled = NO;
}
- (void)enterDonationKey{
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    if (!_dwindow) {
        _dwindow = [[DonationWindowController alloc] init];
    }
    [_dwindow.window makeKeyAndOrderFront:nil];
    
}
- (IBAction)enterDonationKey:(id)sender {
    [self enterDonationKey];
}

- (IBAction)deactivatePatreonLicense:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    [alert setMessageText:NSLocalizedString(@"Do you want to deauthorize your Patreon license?",nil)];
    alert.informativeText = NSLocalizedString(@"By deauthorizing your Patreon license, you will lose access to donor features. However, you may reauthorize your license by registering it again.",nil);
    // Set Message type to Warning
    alert.alertStyle = NSAlertStyleInformational;
    NSModalResponse returncode = [alert runModal];
    if (returncode == NSAlertFirstButtonReturn) {
        [Utility deactivatePatreonLicense:self];
    }
}

- (void)performsendupdatenotification:(int)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        //Enable the Update button if a title is detected
        switch (status) { // 0 - nothing playing; 1 - same episode playing; 21 - Add Title Successful; 22 - Update Title Successful;  51 - Can't find Title; 52 - Add Failed; 53 - Update Failed; 54 - Scrobble Failed;
            case ScrobblerNothingPlaying:
                [self setStatusText:@"Scrobble Status: Idle..."];
                break;
            case ScrobblerSameEpisodePlaying:
                [self setStatusText:@"Scrobble Status: Same Episode Playing, Scrobble not needed."];
                break;
            case ScrobblerUpdateNotNeeded:
                [self setStatusText:@"Scrobble Status: No update needed."];
                break;
            case ScrobblerConfirmNeeded:{
                [self setStatusText:@"Scrobble Status: Please confirm update."];
                NSDictionary * userinfo = @{@"title": haengine.lastscrobble.LastScrobbledTitle,  @"episode": haengine.lastscrobble.LastScrobbledEpisode};
                [self showConfirmationNotification:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",haengine.lastscrobble.LastScrobbledActualTitle,haengine.lastscrobble.LastScrobbledEpisode] updateData:userinfo withIdentifier:haengine.lastscrobble.AniID];
                break;
            }
            case ScrobblerAddTitleSuccessful:
            case ScrobblerUpdateSuccessful:{
                [self setStatusText:@"Scrobble Status: Scrobble Successful..."];
                NSString * notificationmsg;
                if (haengine.lastscrobble.rewatching) {
                    notificationmsg = [NSString stringWithFormat:@"Rewatching %@ Episode %@",haengine.lastscrobble.LastScrobbledActualTitle,haengine.lastscrobble.LastScrobbledEpisode];
                }
                else {
                    notificationmsg = [NSString stringWithFormat:@"%@ Episode %@",haengine.lastscrobble.LastScrobbledActualTitle,haengine.lastscrobble.LastScrobbledEpisode];
                }
                [self showNotification:@"Scrobble Successful." message:notificationmsg withIdentifier:haengine.lastscrobble.AniID];
                //Add History Record
                [HistoryWindow addrecord:haengine.lastscrobble.LastScrobbledActualTitle Episode:haengine.lastscrobble.LastScrobbledEpisode Date:[NSDate date]];
                break;
            }
            case ScrobblerOfflineQueued:
                [self setStatusText:@"Scrobble Status: Scrobble Queued..."];
                [self showNotification:@"Scrobble Queued." message:[NSString stringWithFormat:@"%@ - %@",haengine.lastscrobble.LastScrobbledTitle,haengine.lastscrobble.LastScrobbledEpisode] withIdentifier:@"scrobblequeued"];
                break;
            case ScrobblerTitleNotFound:
                if (!((NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"showcorrection"]).boolValue) {
                    [self setStatusText:NSLocalizedString(@"Scrobble Status: Can't find title. Retrying in 5 mins...",nil)];
                    [self showNotification:NSLocalizedString(@"Couldn't find title.",nil) message:[NSString stringWithFormat:NSLocalizedString(@"Click here to find %@ manually.",nil), haengine.detectedscrobble.FailedTitle] withIdentifier:@"notfound"];
                } 
                break;
            case ScrobblerAddTitleFailed:
            case ScrobblerUpdateFailed:
                [self showNotification:NSLocalizedString(@"Scrobble Unsuccessful.",nil) message:NSLocalizedString(@"Retrying in 5 mins...",nil) withIdentifier:@"scrobblefailed"];
                [self setStatusText:NSLocalizedString(@"Scrobble Status: Scrobble Failed. Retrying in 5 mins...",nil)];
                break;
            case ScrobblerFailed:
                [self showNotification:NSLocalizedString(@"Scrobble Unsuccessful.",nil) message:NSLocalizedString(@"Check user credentials in Preferences. You may need to login again.",nil) withIdentifier:@"badcredentials"];
                [self setStatusText:NSLocalizedString(@"Scrobble Status: Scrobble Failed. User credentials might have expired.",nil)];
                break;
            case ScrobblerInvalidScrobble:
                [self showNotification:@"Invalid Scrobble" message:@"You are trying to scrobble a title that haven't been aired or finished airing yet, which is not allowed." withIdentifier:@"invalidscrobble"];
                [self setStatusText:@"Scrobble Status: Invalid Scrobble."];
                break;
            default:
                break;
        }
    });
}
- (void)performRefreshUI:(int)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (haengine.Success == 1) {
            [findtitle setHidden:true];
            [self setStatusMenuTitleEpisode:haengine.lastscrobble.LastScrobbledActualTitle ? haengine.lastscrobble.LastScrobbledActualTitle : haengine.lastscrobble.LastScrobbledTitle episode:haengine.lastscrobble.LastScrobbledEpisode];
            if (status != 3 && haengine.lastscrobble.confirmed) {
                // Show normal info
                [self updateLastScrobbledTitleStatus:false];
                //Enable Update Status functions
                [self EnableStatusUpdating:YES];
                [confirmupdate setHidden:YES];
                [self showRevertRewatchMenu];
            }
            else {
                // Show that user needs to confirm update
                [self updateLastScrobbledTitleStatus:true];
                [confirmupdate setHidden:NO];
                if (haengine.lastscrobble.LastScrobbledTitleNew) {
                    // Disable Update Status functions for new and unconfirmed titles.
                    [self EnableStatusUpdating:NO];
                    [revertrewatch setHidden:YES];
                }
                else {
                    [self EnableStatusUpdating:YES];
                    [self showRevertRewatchMenu];
                }
            }
            [sharetoolbaritem setEnabled:YES];
            [correcttoolbaritem setEnabled:YES];
            _servicenamemenu.enabled = NO;
            [openAnimePage setEnabled:YES];
            // Show hidden menus
            [self unhideMenus];
            NSDictionary * ainfo = haengine.lastscrobble.LastScrobbledInfo;
            if (ainfo !=nil) { // Checks if Hachidori already populated info about the just updated title.
                [self showAnimeInfo:ainfo];
                switch ([Hachidori currentService]) {
                    case 0:
                        [_shareMenu generateShareMenu:@[[NSString stringWithFormat:@"%@ - %@", haengine.lastscrobble.LastScrobbledActualTitle, haengine.lastscrobble.LastScrobbledEpisode ], [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/anime/%@", haengine.lastscrobble.AniID]]]];
                        break;
                    case 1:
                        [_shareMenu generateShareMenu:@[[NSString stringWithFormat:@"%@ - %@", haengine.lastscrobble.LastScrobbledActualTitle, haengine.lastscrobble.LastScrobbledEpisode ], [NSURL URLWithString:[NSString stringWithFormat:@"https://anilist.co/anime/%@", haengine.lastscrobble.AniID]]]];
                        break;
                    case 2:
                        [_shareMenu generateShareMenu:@[[NSString stringWithFormat:@"%@ - %@", haengine.lastscrobble.LastScrobbledActualTitle, haengine.lastscrobble.LastScrobbledEpisode ], [NSURL URLWithString:[NSString stringWithFormat:@"https://myanimelist.net/anime/%@", haengine.lastscrobble.AniID]]]];
                        break;
                    default:
                        break;
                }
            }
        }
        if (status == ScrobblerTitleNotFound) {
            //Show option to find title
            [findtitle setHidden:false];
            if (((NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"showcorrection"]).boolValue) {
                [self showCorrectionSearchWindow:self];
            }
        }
        // Enable Menu Items
        scrobbleractive = false;
        [self toggleScrobblingUIEnable:true];
    });
    
}

- (void)resetUI {
    // Resets the UI when the user logs out
    [_shareMenu resetShareMenu];
    [updatecorrect setAutoenablesItems:NO];
    [self EnableStatusUpdating:NO];
    [revertrewatch setHidden:YES];
    [sharetoolbaritem setEnabled:NO];
    [correcttoolbaritem setEnabled:NO];
    [openAnimePage setEnabled:NO];
    [findtitle setHidden:YES];
    [confirmupdate setHidden:YES];
    lastupdateheader.hidden = YES;
    updatedtitle.hidden = YES;
    updatedepisode.hidden = YES;
    seperator2.hidden = YES;
    updatecorrectmenu.hidden = YES;
    shareMenuItem.hidden = YES;
    _nowplayingview.hidden = YES;
    _nothingplayingview.hidden = NO;
    _servicenamemenu.enabled = NO;
    [self setStatusToolTip:@"Hachidori"];
}

#pragma mark Timer Functions

- (IBAction)toggletimer:(id)sender {
	//Check to see if a token exist
	if (![Hachidori getCurrentFirstAccount]) {
        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Please log in with your account in Preferences before you enable scrobbling",nil) withIdentifier:@"noaccount"];
    }
	else {
		if (scrobbling == FALSE) {
			[self starttimer];
			[togglescrobbler setTitle:NSLocalizedString(@"Stop Scrobbling",nil)];
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Auto Scrobble is now turned on.",nil) withIdentifier:@"autoscrobble"];
			ScrobblerStatus.objectValue = @"Scrobble Status: Started";
			//Set Scrobbling State to true
			scrobbling = TRUE;
		}
		else {
			[self stoptimer];
			[togglescrobbler setTitle:NSLocalizedString(@"Start Scrobbling",nil)];
			ScrobblerStatus.objectValue = @"Scrobble Status: Stopped";
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Auto Scrobble is now turned off.",nil) withIdentifier:@"autoscrobble"];
			//Set Scrobbling State to false
			scrobbling = FALSE;
		}
	}
	
}
- (void)autostarttimer {
	//Check to see if there is an API Key stored
	if (![Hachidori getCurrentFirstAccount]) {
         [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Unable to start scrobbling since there is no login. Please verify your login in Preferences.",nil) withIdentifier:@"noaccount"];
	}
	else {
		[self starttimer];
		[togglescrobbler setTitle:NSLocalizedString(@"Stop Scrobbling",nil)];
		ScrobblerStatus.objectValue = @"Scrobble Status: Started";
		//Set Scrobbling State to true
		scrobbling = TRUE;
	}
}
- (void)firetimer {
	//Tell haengine to detect and scrobble if necessary.
	NSLog(@"Starting...");
    if (!scrobbleractive) {
        scrobbleractive = true;
        __weak AppDelegate *weakSelf = self;
        // Disable toggle scrobbler and update now menu items
        [self toggleScrobblingUIEnable:false];
        __block NSDictionary *expireddict = [haengine checkexpired];
        if ([self checkRequireRefresh:expireddict]) {
            scrobbleractive = false;
            [self refreshToken:^(bool success, NSArray *failedservices) {
                if (success) {
                    [weakSelf firetimer];
                }
                else {
                    [self showFailedRefreshTokenNotice:failedservices];
                }
            } withExpiredDict:expireddict];
            return;
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseAutoExceptions"]) {
            // Check for latest list of Auto Exceptions automatically each week
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"]) {
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"] timeIntervalSinceNow] < -604800) {
                    // Has been 1 Week, update Auto Exceptions
                    [AutoExceptions updateAutoExceptions];
                }
            }
			else {
				// First time, populate
				[AutoExceptions updateAutoExceptions];
			}
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseAnimeRelations"]) {
            // Check for latest list of Anime Relations automatically each week
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"AnimeRelationsLastUpdated"]) {
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"AnimeRelationsLastUpdated"] timeIntervalSinceNow] < -604800) {
                    // Has been 1 Week, update Anime Relations
                    [AnimeRelations updateRelations];
                }
            }
            else {
                // First time, populate
                [AnimeRelations updateRelations];
            }
        }
        int status = 0;
        for (int i = 0; i < 2; i++) {
            if (i == 0) {
                if ([haengine getQueueCount] > 0 && haengine.online) {
                    NSDictionary * status = [haengine scrobblefromqueue];
                    int success = [status[@"success"] intValue];
                    int fail = [status[@"fail"] intValue];
                    bool confirmneeded = [status[@"confirmneeded"] boolValue];
                    if (confirmneeded) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self setStatusText:@"Scrobble Status: Please confirm update."];
                            NSDictionary * userinfo = @{@"title": haengine.lastscrobble.LastScrobbledTitle,  @"episode": haengine.lastscrobble.LastScrobbledEpisode};
                            [self showConfirmationNotification:@"Confirm Update" message:[NSString stringWithFormat:@"Click here to confirm update for %@ Episode %@.",haengine.lastscrobble.LastScrobbledActualTitle,haengine.lastscrobble.LastScrobbledEpisode] updateData:userinfo withIdentifier:haengine.lastscrobble.AniID];
                        });
                        break;
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showNotification:@"Updated Queued Items" message:[NSString stringWithFormat:@"%i scrobbled successfully and %i failed",success, fail] withIdentifier:@"queued"];
                        });
                    }
                    

                }
            }
            else {
                status = [haengine startscrobbling];
                [self performsendupdatenotification:status];
            }
        }
        [self performRefreshUI:status];
    }
}
- (void)starttimer {
	NSLog(@"Auto Scrobble Started.");
    timer = [MSWeakTimer scheduledTimerWithTimeInterval:[[(NSNumber *)[NSUserDefaults standardUserDefaults] valueForKey:@"timerinterval"] intValue]
                                                 target:self
                                               selector:@selector(firetimer)
                                               userInfo:nil
                                                repeats:YES
                                          dispatchQueue:_privateQueue];
}
- (void)stoptimer {
	NSLog(@"Auto Scrobble Stopped.");
	//Stop Timer
	[timer invalidate];
}

- (IBAction)updatenow:(id)sender{
    if ([Hachidori getCurrentFirstAccount]) {
        dispatch_async(_privateQueue, ^{
            [self firetimer];
        });
    }
    else
        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Please log in with your account in Preferences before using this program",nil) withIdentifier:@"noaccount"];
}

#pragma mark Correction
- (IBAction)showCorrectionSearchWindow:(id)sender {
    bool isVisible = window.visible;
    // Stop Timer temporarily if scrobbling is turned on
    if (scrobbling == TRUE) {
        [self stoptimer];
    }
    fsdialog = [FixSearchDialog new];
    // Check if Confirm is on for new title. If so, then disable ability to delete title.
    if ((!confirmupdate.hidden && haengine.lastscrobble.LastScrobbledTitleNew) || !findtitle.hidden) {
        [fsdialog setCorrection:YES];
        [fsdialog setAllowDelete:NO];
    }
    else {
        [fsdialog setCorrection:YES];
        [fsdialog setAllowDelete:YES];
    }
    if (!findtitle.hidden) {
        //Use failed title
         fsdialog.searchquery = haengine.detectedscrobble.FailedTitle;
    }
    else {
        //Get last scrobbled title
        fsdialog.searchquery = haengine.lastscrobble.LastScrobbledTitle;
    }
    if (isVisible) {
        [self disableUpdateItems]; //Prevent user from opening up another modal window if access from Status Window
        [NSApp beginSheet:fsdialog.window
           modalForWindow:window modalDelegate:self
           didEndSelector:@selector(correctionDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }
    else {
        [NSApp beginSheet:fsdialog.window
           modalForWindow:nil modalDelegate:self
           didEndSelector:@selector(correctionDidEnd:returnCode:contextInfo:)
              contextInfo:(void *)nil];
    }

}
- (void)correctionDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == 1) {
            if (haengine.lastscrobble  && fsdialog.selectedaniid.intValue == haengine.lastscrobble.AniID.intValue) {
                NSLog(@"ID matches, correction not needed.");
            }
            else {
                BOOL correctonce = [fsdialog getcorrectonce];
				if (!findtitle.hidden) {
					 [self addtoExceptions:haengine.detectedscrobble.FailedTitle newtitle:fsdialog.selectedtitle showid:fsdialog.selectedaniid.stringValue threshold:fsdialog.selectedtotalepisodes season:haengine.detectedscrobble.FailedSeason];
				}
                else if (haengine.lastscrobble && haengine.lastscrobble.LastScrobbledEpisode.intValue == fsdialog.selectedtotalepisodes) {
                    // Detected episode equals the total episodes, do not add a rule and only do a correction just once.
                    correctonce = true;
                }
				else if (!correctonce) {
                    // Add to Exceptions
					 [self addtoExceptions:haengine.lastscrobble.LastScrobbledTitle newtitle:fsdialog.selectedtitle showid:fsdialog.selectedaniid.stringValue threshold:fsdialog.selectedtotalepisodes season:haengine.lastscrobble.DetectedSeason];
				}
                if([fsdialog getdeleteTitleonCorrection]) {
                    if([haengine removetitle:haengine.lastscrobble.AniID withService:[Hachidori currentService]]) {
                        NSLog(@"Removal Successful");
                    }
                }
                NSLog(@"Updating corrected title...");
                int status;
				if (!findtitle.hidden) {
					status = [haengine scrobbleagain:haengine.detectedscrobble.FailedTitle Episode:haengine.detectedscrobble.FailedEpisode correctonce:false];
				}
                else if (correctonce) {
                    status = [haengine scrobbleagain:fsdialog.selectedtitle Episode:haengine.lastscrobble.LastScrobbledEpisode correctonce:true];
                }
				else {
                    status = [haengine scrobbleagain:haengine.lastscrobble.LastScrobbledTitle Episode:haengine.lastscrobble.LastScrobbledEpisode correctonce:false];
				}
					
                switch (status) {
                    case ScrobblerSameEpisodePlaying:
                    case ScrobblerUpdateNotNeeded:
                    case ScrobblerAddTitleSuccessful:
                    case ScrobblerUpdateSuccessful: {
                        [self setStatusText:NSLocalizedString(@"Scrobble Status: Correction Successful...",nil)];
                        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Correction was successful",nil) withIdentifier:@"correctionsuccess"];
                        [self setStatusMenuTitleEpisode:haengine.lastscrobble.LastScrobbledActualTitle ? haengine.lastscrobble.LastScrobbledActualTitle : haengine.lastscrobble.LastScrobbledTitle episode:haengine.lastscrobble.LastScrobbledEpisode];
                        [self updateLastScrobbledTitleStatus:false];
	                    if (!findtitle.hidden) {
	                        //Unhide menus and enable functions on the toolbar
	                        [self unhideMenus];
	                        [sharetoolbaritem setEnabled:YES];
	                        [correcttoolbaritem setEnabled:YES];
                            [self EnableStatusUpdating:YES];
                            [openAnimePage setEnabled:YES];
                            [self showRevertRewatchMenu];
	                    }
                        //Show Anime Correct Information
                        NSDictionary * ainfo = haengine.lastscrobble.LastScrobbledInfo;
                        [self showAnimeInfo:ainfo];
                        [findtitle setHidden:YES];
                        [confirmupdate setHidden:true];
						//Regenerate Share Items
                        switch ([Hachidori currentService]) {
                            case 0:
                                [_shareMenu generateShareMenu:@[[NSString stringWithFormat:@"%@ - %@", haengine.lastscrobble.LastScrobbledActualTitle, haengine.lastscrobble.LastScrobbledEpisode ], [NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/anime/%@", haengine.lastscrobble.AniID]]]];
                                break;
                            case 1:
                                [_shareMenu generateShareMenu:@[[NSString stringWithFormat:@"%@ - %@", haengine.lastscrobble.LastScrobbledActualTitle, haengine.lastscrobble.LastScrobbledEpisode ], [NSURL URLWithString:[NSString stringWithFormat:@"https://anilist.co/anime/%@", haengine.lastscrobble.AniID]]]];
                                break;
                            default:
                                break;
                        }
                        break;
                    }
                    default:
                        [self setStatusText:NSLocalizedString(@"Scrobble Status: Correction unsuccessful...",nil)];
                        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Correction was not successful.",nil) withIdentifier:@"correctionfailed"];
                        break;
                }
            }
        }
        else {
        }
    fsdialog = nil;
    [self enableUpdateItems]; // Enable Update Items
    //Restart Timer
    if (scrobbling == TRUE) {
        [self starttimer];
    }
}
- (void)addtoExceptions:(NSString *)detectedtitle newtitle:(NSString *)title showid:(NSString *)showid threshold:(int)threshold season:(int)season {
    NSManagedObjectContext * moc = managedObjectContext;
    NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
    allExceptions.entity = [NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc];
    NSError * error = nil;
    NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
    BOOL exists = false;
    for (NSManagedObject * entry in exceptions) {
        int offset = ((NSNumber *)[entry valueForKey:@"episodeOffset"]).intValue;
        if ([detectedtitle isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]] && offset == 0) {
            exists = true;
            break;
        }
    }
    if (!exists) {
        // Add exceptions to Exceptions Entity
        [ExceptionsCache addtoExceptions:detectedtitle correcttitle:title aniid:showid threshold:threshold offset:0 detectedSeason:season];
    }
    //Check if title exists in cache and then remove it
    [ExceptionsCache checkandRemovefromCache:detectedtitle detectedSeason:season withService:0];

}

#pragma mark History Window functions

- (IBAction)showhistory:(id)sender
{
		//Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
		[NSApp activateIgnoringOtherApps:YES];
    if (!historywindowcontroller) {
        historywindowcontroller = [[HistoryWindow alloc] init];
    }
    [historywindowcontroller.window makeKeyAndOrderFront:nil];

}
#pragma mark StatusIconTooltip, Status Text, Last Scrobbled Title Setters


- (void)setStatusToolTip:(NSString*)toolTip
{
    statusItem.toolTip = toolTip;
}
- (void)setStatusText:(NSString*)messagetext
{
	ScrobblerStatus.objectValue = messagetext;
}
- (void)setLastScrobbledTitle:(NSString*)messagetext
{
	LastScrobbled.objectValue = messagetext;
}
- (void)setStatusMenuTitleEpisode:(NSString *)title episode:(NSString *) episode{
    //Set New Title and Episode
    updatedtitle.title = title;
    updatedepisode.title = [NSString stringWithFormat:NSLocalizedString(@"Episode %@",nil), episode];
}
- (void)updateLastScrobbledTitleStatus:(BOOL)pending{
    if (pending) {
        [updatecorrect setAutoenablesItems:NO];
        [lastupdateheader setTitle:NSLocalizedString(@"Pending:",nil)];
        [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Pending: %@ - Episode %@ playing from %@",nil),haengine.lastscrobble.LastScrobbledTitle,haengine.lastscrobble.LastScrobbledEpisode, haengine.lastscrobble.LastScrobbledSource]];
        [self setStatusToolTip:[NSString stringWithFormat:NSLocalizedString(@"Hachidori - %@ - %@ (Pending)",nil),haengine.lastscrobble.LastScrobbledActualTitle,haengine.lastscrobble.LastScrobbledEpisode]];
    }
    else if (!haengine.online) {
        [updatecorrect setAutoenablesItems:NO];
        [lastupdateheader setTitle:NSLocalizedString(@"Queued:",nil)];
        [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Queued: %@ - Episode %@ playing from %@",nil),haengine.lastscrobble.LastScrobbledTitle,haengine.lastscrobble.LastScrobbledEpisode, haengine.lastscrobble.LastScrobbledSource]];
        [self setStatusToolTip:[NSString stringWithFormat:NSLocalizedString(@"Hachidori - %@ - %@ (Queued)",nil),haengine.lastscrobble.LastScrobbledTitle,haengine.lastscrobble.LastScrobbledEpisode]];
    }
    else {
        [updatecorrect setAutoenablesItems:YES];
        if (haengine.lastscrobble.rewatching) {
            [lastupdateheader setTitle:NSLocalizedString(@"Rewatching:",nil)];
            [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Rewatching: %@ - Episode %@ playing from %@",nil),haengine.lastscrobble.LastScrobbledTitle,haengine.lastscrobble.LastScrobbledEpisode, haengine.lastscrobble.LastScrobbledSource]];
        }
        else {
            [lastupdateheader setTitle:NSLocalizedString(@"Last Scrobbled:",nil)];
            [self setLastScrobbledTitle:[NSString stringWithFormat:NSLocalizedString(@"Last Scrobbled: %@ - Episode %@ playing from %@",nil),haengine.lastscrobble.LastScrobbledTitle,haengine.lastscrobble.LastScrobbledEpisode, haengine.lastscrobble.LastScrobbledSource]];
        }
        [self setStatusToolTip:[NSString stringWithFormat:NSLocalizedString(@"Hachidori - %@ - %@",nil),haengine.lastscrobble.LastScrobbledActualTitle,haengine.lastscrobble.LastScrobbledEpisode]];
    }
}

#pragma mark Update Status functions

- (IBAction)updatestatus:(id)sender {
    __block NSDictionary *expireddict = [haengine checkexpired];
    if ([self checkRequireRefresh:expireddict]) {
        [self refreshToken:^(bool success, NSArray *failedservices) {
            if (success) {
                [self showUpdateDialog:self.window];
                [self disableUpdateItems];
            }
            else {
                [self showFailedRefreshTokenNotice:failedservices];
            }
        } withExpiredDict:expireddict];
    }
    else {
        [self showUpdateDialog:self.window];
        [self disableUpdateItems];
    }
}
- (IBAction)updatestatusmenu:(id)sender{
    [self showUpdateDialog:nil];
}
- (void)showUpdateDialog:(NSWindow *) w{
    [NSApp activateIgnoringOtherApps:YES];
    if (!_updatewindow) {
        _updatewindow = [StatusUpdateWindow new];
        // Set completion handler
        __weak AppDelegate *weakself = self;
        _updatewindow.completion = ^void(int returnCode){
            [weakself updateDidEnd:returnCode];
        };
    }
    // Show Dialog
    [_updatewindow showUpdateDialog:w withHachidori:haengine];
}
- (void)updateDidEnd:(int)returnCode {
    NSString * tmpepisode = _updatewindow.episodefield.stringValue;
    int tmpscore = 0;
    switch ([Hachidori currentService]) {
        case 0:
            tmpscore = (int)_updatewindow.showscore.selectedTag;
            break;
        case 1:
            if (haengine.ratingtype == ratingPoint100 || haengine.ratingtype == ratingPoint10Decimal) {
                tmpscore = [AniListScoreConvert convertScoretoScoreRaw:_updatewindow.advancedscorefield.floatValue withScoreType:haengine.ratingtype];
            }
            else {
                tmpscore = [AniListScoreConvert convertScoretoScoreRaw:_updatewindow.showscore.selectedTag withScoreType:haengine.ratingtype];
            }
            break;
    }

    NSString *tmpshowstatus = _updatewindow.showstatus.titleOfSelectedItem;
    NSString *tmpnotes = _updatewindow.notes.textStorage.string;
    bool tmpprivate = (bool)_updatewindow.isPrivate.state;
    if (returnCode == 1) {
        // Check if Episode field is empty. If so, set it to last scrobbled episode
        bool episodechanged = false;
        if (tmpepisode.length == 0) {
            tmpepisode = [NSString stringWithFormat:@"%i", haengine.lastscrobble.DetectedCurrentEpisode];
        }
        if (tmpepisode.intValue != haengine.lastscrobble.DetectedCurrentEpisode) {
            episodechanged = true; // Used to update the status window
        }
        [haengine updatestatus:haengine.lastscrobble.AniID episode:tmpepisode score:tmpscore watchstatus:tmpshowstatus notes:tmpnotes isPrivate:tmpprivate completion:^(bool success) {
            if (success) {
                [self setStatusText:NSLocalizedString(@"Scrobble Status: Updating of Watch Status/Score Successful.",nil)];
                if (episodechanged) {
                    // Update the tooltip, menu and last scrobbled title
                    [self setStatusMenuTitleEpisode:haengine.lastscrobble.LastScrobbledActualTitle ? haengine.lastscrobble.LastScrobbledActualTitle : haengine.lastscrobble.LastScrobbledTitle episode:haengine.lastscrobble.LastScrobbledEpisode];
                    [self updateLastScrobbledTitleStatus:false];
                }
                [self.haengine multiscrobbleWithType:MultiScrobbleTypeEntryupdate withTitleID:haengine.lastscrobble.AniID];
            }
            else {
                [self setStatusText:NSLocalizedString(@"Scrobble Status: Unable to update Watch Status/Score.",nil)];
            }
            //If scrobbling is on, restart timer
            if (scrobbling == TRUE) {
                [self starttimer];
            }
            [self enableUpdateItems]; //Reenable update items
        } withService:[Hachidori currentService]];
    }
    else {
        //If scrobbling is on, restart timer
        if (scrobbling == TRUE) {
            [self starttimer];
        }
        [self enableUpdateItems]; //Reenable update items
    }
}

- (IBAction)revertRewatch:(id)sender {
    //Show Prompt
    NSAlert * alert = [[NSAlert alloc] init] ;
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Do you want to stop rewatching %@?",nil),haengine.lastscrobble.LastScrobbledTitle];
    [alert setInformativeText:NSLocalizedString(@"This will revert the title status back to it's completed state.",nil)];
    // Set Message type to Informational
    alert.alertStyle = NSInformationalAlertStyle;
    if ([alert runModal]== NSAlertFirstButtonReturn) {
        // Revert title
        BOOL success = [haengine stopRewatching:haengine.lastscrobble.AniID withService:[Hachidori currentService]];
        if (success) {
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@'s rewatch status has been reverted.",nil), haengine.lastscrobble.LastScrobbledTitle] withIdentifier:@"rewatchreverted"];
            // Show Correct State in the UI
            [self showRevertRewatchMenu];
            [self updateLastScrobbledTitleStatus:false];
        }
        else {
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:NSLocalizedString(@"Rewatch revert was unsuccessful.",nil) withIdentifier:@"rewatchreverted"];
        }
    }
}

#pragma mark Notification Center and Title/Update Confirmation

- (void)showNotification:(NSString *)title message:(NSString *) message withIdentifier:(NSString *)identifier {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = nil;
    notification.identifier = [NSString stringWithFormat:@"%@-%@",identifier, [NSDate date]];
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
- (void)showConfirmationNotification:(NSString *)title message:(NSString *) message updateData:(NSDictionary *)d withIdentifier:(NSString *)identifier{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.identifier = [NSString stringWithFormat:@"%@-%@",identifier, [NSDate date]];
    notification.soundName = NSUserNotificationDefaultSoundName;
    notification.userInfo = d;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}
- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([notification.title isEqualToString:@"Confirm Update"] && !confirmupdate.hidden) {
        NSString * title = (notification.userInfo)[@"title"];
        NSString * episode = (notification.userInfo)[@"episode"];
        // Only confirm update if the title and episode is the same with the last scrobbled.
        if ([haengine.lastscrobble.LastScrobbledTitle isEqualToString:title] && episode.intValue == haengine.lastscrobble.LastScrobbledEpisode.intValue) {
            //Confirm Update
            [self performconfirmupdate];
        }
        else {
            return;
        }
    }
    else if ([notification.title isEqualToString:@"Couldn't find title."] && !findtitle.hidden) {
        //Find title
        [self showCorrectionSearchWindow:nil];
    }
}
- (IBAction)confirmupdate:(id)sender {
    __block NSDictionary *expireddict = [haengine checkexpired];
    if ([self checkRequireRefresh:expireddict]) {
        [self refreshToken:^(bool success, NSArray *failedservices) {
            if (success) {
                [self performconfirmupdate];
            }
            else {
                [self showFailedRefreshTokenNotice:failedservices];
            }
        } withExpiredDict:expireddict];
    }
    else {
        [self performconfirmupdate];
    }
}
- (void)performconfirmupdate{
    dispatch_async(_privateQueue, ^{

    BOOL success = [haengine confirmupdate];
    if (success) {
         dispatch_async(dispatch_get_main_queue(), ^{
            [self updateLastScrobbledTitleStatus:false];
            [HistoryWindow addrecord:haengine.lastscrobble.LastScrobbledActualTitle Episode:haengine.lastscrobble.LastScrobbledEpisode Date:[NSDate date]];
            [confirmupdate setHidden:YES];
            [self setStatusText:@"Scrobble Status: Update was successful."];
            [self showNotification:NSLocalizedString(@"Hachidori",nil) message:[NSString stringWithFormat:@"%@ Episode %@ has been updated.",haengine.lastscrobble.LastScrobbledActualTitle,haengine.lastscrobble.LastScrobbledEpisode] withIdentifier:haengine.lastscrobble.AniID];
            if (haengine.lastscrobble.LastScrobbledTitleNew) {
                // Enable Update Status functions for new and unconfirmed titles.
                [self EnableStatusUpdating:YES];
            }
             [self showRevertRewatchMenu];
         });
    }
    else {
         dispatch_async(dispatch_get_main_queue(), ^{
        [self showNotification:NSLocalizedString(@"Hachidori",nil) message:@"Failed to confirm update. Please try again later." withIdentifier:@"confirmfailed"];
        [self setStatusText:@"Unable to confirm update."];
         });
    }
            });
}
#pragma mark Hotkeys
- (void)registerHotkey {
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceScrobbleNowShortcut toAction:^{
         // Scrobble Now Global Hotkey
         dispatch_async(_privateQueue, ^{
             if ([Hachidori getCurrentFirstAccount] && !panelactive) {
                 [self firetimer];
             }
         });
     }];
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceShowStatusMenuShortcut toAction:^{
         // Status Window Toggle Global Hotkey
         [self togglescrobblewindow:nil];
     }];
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceToggleScrobblingShortcut toAction:^{
         // Auto Scrobble Toggle Global Hotkey
         [self toggletimer:nil];
     }];
    [[MASShortcutBinder sharedBinder]
     bindShortcutWithDefaultsKey:kPreferenceConfirmUpdateShortcut toAction:^{
         // Confirm Update Hotkey
         if (!confirmupdate.hidden) {
             [self performconfirmupdate];
         }
     }];
}

#pragma mark Misc
- (void)showAnimeInfo:(NSDictionary *)d {
    //Empty
    animeinfo.string = @"";
    // Show Actual Title
    [self appendToAnimeInfo:haengine.lastscrobble.LastScrobbledActualTitle];
    [self appendToAnimeInfo:@""];
    //Description
    NSString *anidescription = d[@"synopsis"];
    if (d[@"synopsis"] != [NSNull null]) {
        [self appendToAnimeInfo:@"Description"];
        
    }
    else {
        anidescription = @"No description available.";
    }
    [self appendToAnimeInfo:anidescription];
    //Meta Information
    [self appendToAnimeInfo:@""];
    [self appendToAnimeInfo:@"Other Information"];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Classification: %@", d[@"classification"]]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Start Date: %@", d[@"start_date"]]];
    if (d[@"end_date"] != [NSNull null] && ((NSString *)d[@"end_date"]).length > 0) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"End Date: %@", d[@"end_date"]]];
    }
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Airing Status: %@", d[@"status"]]];
    NSString *epi;
    if (d[@"episodes"] == [NSNull null]) {
        epi = @"Unknown";
    }
    else {
        epi = d[@"episodes"];
    }
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Episodes: %@", epi]];
    [self appendToAnimeInfo:[NSString stringWithFormat:@"Popularity: %@", d[@"popularity_rank"]]];
    if (d[@"favorited_count"]) {
        [self appendToAnimeInfo:[NSString stringWithFormat:@"Favorited: %@", d[@"favorited_count"]]];
    }
    self.animeinfo.textColor = NSColor.controlTextColor;
    //Image
    NSImage *dimg = (d[@"image_url"] != [NSNull null]) ? [[NSImage alloc]initByReferencingURL:[NSURL URLWithString: (NSString *)d[@"image_url"]]] : [NSImage imageNamed:@"missing"]; //Downloads Image
    img.image = dimg; //Get the Image for the title
    // Refresh view
    _nowplayingview.hidden = NO;
    _nothingplayingview.hidden = YES;
}

- (void)appendToAnimeInfo:(NSString*)text
{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ \n", text]];
        
        [animeinfo.textStorage appendAttributedString:attr];
}
- (void)showRevertRewatchMenu{
    if (haengine.lastscrobble.rewatching) {
        [revertrewatch setHidden:NO];
    }
    else {
        [revertrewatch setHidden:YES];
    }
}
- (NSDictionary *)getNowPlaying{
	// Outputs Currently Playing information into JSON
	NSMutableDictionary * output = [NSMutableDictionary new];
	if ((haengine.lastscrobble.getLastScrobbledTitle).length > 0) {
		output[@"id"] = haengine.lastscrobble.AniID;
		output[@"scrobbledtitle"] = haengine.lastscrobble.LastScrobbledTitle;
		output[@"scrobbledactualtitle"] = haengine.lastscrobble.LastScrobbledActualTitle;
		output[@"scrobbledEpisode"] = haengine.lastscrobble.LastScrobbledEpisode;
		output[@"source"] = haengine.lastscrobble.LastScrobbledSource;
	}
	return output;
}
- (IBAction)showLastScrobbledInformation:(id)sender {
    //Open the anime's page on the current service in the default web browser
    switch ([Hachidori currentService]) {
        case 0:
             [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://kitsu.io/anime/%@", haengine.lastscrobble.AniID]]];
            break;
        case 1:
             [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://anilist.co/anime/%@", haengine.lastscrobble.AniID]]];
            break;
        case 2:
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://myanimelist.net/anime/%@", haengine.lastscrobble.AniID]]];
            break;
        default:
            break;
    }
}
#pragma mark Torrent Browser
- (IBAction)openTorrentBrowser:(id)sender {
#ifdef oss
#else
    //Since LSUIElement is set to 1 to hide the dock icon, it causes unattended behavior of having the program windows not show to the front.
    [NSApp activateIgnoringOtherApps:YES];
    [_tbc.window makeKeyAndOrderFront:self];
    [_tbc showwarning];
#endif
}

#pragma mark Reauthorize Prompt
- (void)showReauthorizePrompt:(NSArray *)failedservices {
    NSAlert * alert = [[NSAlert alloc] init];
    NSString *failedservicesstr = [failedservices componentsJoinedByString:@","];
    [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
    [alert setMessageText:NSLocalizedString(@"Unable to Refresh Credentials",nil)];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The following accounts for the following services failed to refresh the access token used to access your list's entry status. You need to reauthorize your account by removing and reauthorize your accounts for the following services: \n\n %@ \n Do you want to open Preferences to reauthorize your account now?",nil), failedservicesstr]];
    // Set Message type to Warning
    alert.alertStyle = NSInformationalAlertStyle;
    if ([alert runModal]== NSAlertFirstButtonReturn) {
        // Show Preference Window and go to Login Preference Pane
        [NSApp activateIgnoringOtherApps:YES];
        [self.preferencesWindowController showWindow:nil];
        [(MASPreferencesWindowController *)self.preferencesWindowController selectControllerAtIndex:1];
    }
}

#pragma mark Crash Reporting

#ifdef oss
#else
- (BOOL)crashes:(MSACCrashes *)crashes shouldProcessErrorReport:(MSACErrorReport *)errorReport {
    __block bool send = false;
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"sendanalytics"]) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            _cwincontroller = [CrashWindowController new];
            if ([NSApp runModalForWindow:_cwincontroller.window]) {
                send = true;
            }
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    return send;
}

- (NSArray<MSACErrorAttachmentLog *> *)attachmentsWithCrashes:(MSACCrashes *)crashes forErrorReport:(MSACErrorReport *)errorReport {
    NSString *log = [NSString stringWithContentsOfFile:[Utility retrieveApplicationSupportDirectory:@"Hachidori.log"] encoding:NSUTF8StringEncoding error:NULL];
    __block NSString *additionalInfo = @"";
    __block bool sendlog;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        sendlog = _cwincontroller.includelog.state;
        additionalInfo = _cwincontroller.commentstextview.string;
        dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    NSString *finalstring = [NSString stringWithFormat:@"Comments: \n%@\n\n Log:\n%@", additionalInfo, log && sendlog ? log : @"Log file not included"];
    MSACErrorAttachmentLog *attach1 = [MSACErrorAttachmentLog attachmentWithText:finalstring filename:[Utility retrieveApplicationSupportDirectory:@"Hachidori.log"]];
    return @[attach1];
}

- (void)crashes:(MSACCrashes *)crashes didSucceedSendingErrorReport:(MSACErrorReport *)errorReport {
    [self showNotification:@"Crash Report Sent" message:@"Thanks for reporting an issue." withIdentifier:[NSString stringWithFormat:@"error-%f", NSDate.date.timeIntervalSince1970]];
}

- (void)crashes:(MSACCrashes *)crashes didFailSendingErrorReport:(MSACErrorReport *)errorReport withError:(NSError *)error {
    [self showNotification:@"Crash Report Failed" message:@"Couldn't send crash report." withIdentifier:[NSString stringWithFormat:@"error-%f", NSDate.date.timeIntervalSince1970]];
}
#endif

#pragma mark Token Refresh
- (void)refreshToken:(void(^)(bool success, NSArray *failedservices))completion withExpiredDict:(NSDictionary *)expireddict {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"multiscrobbleenabled"]) {
        bool requirerefresh = [self checkRequireRefresh:expireddict];
        if (requirerefresh) {
            __weak AppDelegate *weakself = self;
            [haengine refreshtokenwithdictionary:expireddict successHandler:^(bool success, int numfailed, NSArray *failedservices) {
                if (!success) {
                    for (NSString *failedservicestr in failedservices) {
                        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
                        if ([failedservicestr isEqualToString:@"anilist"]) {
                            [defaults setBool:YES forKey:@"AniListRefreshFailed"];
                        }
                        else if ([failedservicestr isEqualToString:@"kitsu"]) {
                            [defaults setBool:YES forKey:@"KitsuRefreshFailed"];
                        }
                        else if ([failedservicestr isEqualToString:@"myanimelist"]) {
                            [defaults setBool:YES forKey:@"MALRefreshFailed"];
                        }
                    }
                    completion(false, failedservices);
                }
                else {
                    completion(true, nil);
                }
                return;
            }];
            return;
        }
    }
    else {
        if (((NSNumber *)expireddict[Hachidori.currentServiceName.lowercaseString]).boolValue) {
            __weak AppDelegate *weakself = self;
            [haengine refreshtokenWithService:[Hachidori currentService] successHandler:^(bool success) {
                if (success) {
                    completion(true, nil);
                }
                else {
                    completion(false, @[Hachidori.currentServiceName.lowercaseString]);
                }
                return;
            }];
            return;
        }
    }
}
- (bool)checkRequireRefresh:(NSDictionary *)expireddict {
    bool requirerefresh = false;
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"multiscrobbleenabled"]) {
        for (NSDictionary *servicekey in expireddict.allKeys) {
            if (((NSNumber *)expireddict[servicekey]).boolValue) {
                requirerefresh = true;
                break;
            }
        }
    }
    else {
        requirerefresh = ((NSNumber *)expireddict[Hachidori.currentServiceName.lowercaseString]).boolValue;
    }
    return requirerefresh;
}
- (void)showFailedRefreshTokenNotice:(NSArray *)failedservices {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"multiscrobbleenabled"]) {
        [self showNotification:@"Can't Refresh Token." message:@"Please reauthorize your account and try again." withIdentifier:@"badcredentials"];
        [self performRefreshUI:ScrobblerRefreshTokenFailed];
        [self showReauthorizePrompt:failedservices];
    }
    else {
        [self showNotification:[NSString stringWithFormat:@"Can't Refresh %@ Token.", Hachidori.currentServiceName] message:[NSString stringWithFormat:@"Please reauthorize your %@ account and try again.", Hachidori.currentServiceName] withIdentifier:@"badcredentials"];
        [self performRefreshUI:ScrobblerRefreshTokenFailed];
        [self showReauthorizePrompt:@[Hachidori.currentServiceName]];
    }
}
@end
